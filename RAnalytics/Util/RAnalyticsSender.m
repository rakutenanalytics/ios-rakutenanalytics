#import "RAnalyticsSender.h"
#import "_RAnalyticsDatabase.h"
#import "_RAnalyticsHelpers.h"

NSString *const RAnalyticsWillUploadNotification    = @"com.rakuten.esd.sdk.notifications.analytics.rat.will_upload";
NSString *const RAnalyticsUploadFailureNotification = @"com.rakuten.esd.sdk.notifications.analytics.rat.upload_failed";
NSString *const RAnalyticsUploadSuccessNotification = @"com.rakuten.esd.sdk.notifications.analytics.rat.upload_succeeded";

static const unsigned int    _RATTableBlobLimit = 5000u;
static const unsigned int    _RATBatchSize      = 16u;

@interface RAnalyticsSender()

@property (copy, nonatomic) NSURL          *endpoint;
@property (copy, nonatomic) NSString       *databaseTableName;
@property (nonatomic) _RAnalyticsDatabase* database;

/*
 * uploadTimer is used to throttle uploads. A call to -_scheduleBackgroundUpload
 * will do nothing if uploadTimer is not nil.
 *
 * Since we don't want to start a new upload until the previous one has been fully
 * processed, though, we only invalidate that timer at the very end of the HTTP
 * request. That's why we also need uploadRequested, set by -_scheduleBackgroundUpload,
 * so that we know we have to restart our timer at that point.
 */
@property (nonatomic) BOOL                      uploadRequested;
@property (nonatomic) BOOL                      zeroBatchingDelayUploadInProgress;
@property (nonatomic) NSTimer                  *uploadTimer;
@property (nonatomic) NSTimeInterval            uploadTimerInterval;
@property (nonatomic, copy) BatchingDelayBlock  batchingDelayBlock;
@end

@implementation RAnalyticsSender

- (instancetype)initWithEndpoint:(NSURL *)endpoint databaseName:(NSString *)databaseName databaseTableName:(NSString *)tableName
{
    if (!endpoint.absoluteString.length || !databaseName.length || !tableName.length) return nil;
    if (self = [super init])
    {
        _endpoint = endpoint;
        _databaseTableName = tableName;
        _database = [_RAnalyticsDatabase databaseWithConnection:mkAnalyticsDBConnectionWithName(databaseName)];
        
        /*
         * Listen to new session start event
         */
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(_startNewSessionEvent)
                                                   name:UIApplicationDidBecomeActiveNotification
                                                 object:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)sendJSONOject:(id)obj
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:0];
    RAnalyticsDebugLog(@"Spooling record with the following payload: %@", [NSString.alloc initWithData:jsonData encoding:NSUTF8StringEncoding]);
    [self _storeAndSendEventData:jsonData];
}

- (void)setBatchingDelayBlock:(BatchingDelayBlock)batchingDelayBlock
{
    _batchingDelayBlock = batchingDelayBlock;
}

- (void)_storeAndSendEventData:(NSData *)jsonData
{
    typeof(self) __weak weakSelf = self;
    [_database insertBlob:jsonData
                     into:_databaseTableName
                    limit:_RATTableBlobLimit
                     then:^{
                         typeof(weakSelf) __strong strongSelf = weakSelf;
                         [strongSelf _scheduleUploadOrPerformImmediately];
                     }];
}

- (void)_scheduleUploadOrPerformImmediately
{
    if (_batchingDelayBlock)
    {
        NSTimeInterval delay =  _batchingDelayBlock();
        _uploadTimerInterval = (MIN(MAX(0, delay), 60));
    }

    /*
     * Upload immediately if batching delay is 0 and a request isn't in progress.
     * Otherwise, schedule the upload in background.
     */
    if (_uploadTimerInterval <= 0 &&
        !_uploadTimer.isValid &&
        !_zeroBatchingDelayUploadInProgress)
    {
        _zeroBatchingDelayUploadInProgress = YES;
        dispatch_async(dispatch_get_main_queue(), ^{ [self _doBackgroundUpload]; });
    }
    else
    {
        [self _scheduleBackgroundUpload];
    }
}

- (void)_doBackgroundUpload
{
    /*
     * Get a group of records and start uploading them.
     */

    typeof(self) __weak weakSelf = self;
    [_database fetchBlobs:_RATBatchSize
                     from:_databaseTableName
                     then:^(NSArray<NSData *> *__nullable blobs, NSArray<NSNumber *> *__nullable identifiers) {
                         typeof(weakSelf) __strong strongSelf = weakSelf;
                         if (blobs)
                         {
                             RAnalyticsDebugLog(@"Records fetched from DB table %@, now upload them", _databaseTableName);
                             [strongSelf _doBackgroundUploadWithRecords:blobs identifiers:identifiers];
                         }
                         else
                         {
                             RAnalyticsDebugLog(@"No records found in DB table %@ so end upload", _databaseTableName);
                             [strongSelf _backgroundUploadEnded];
                         }
                     }];
}

/*
 * Called by -_doBackgroundUpload only if previously-saved records were found.
 */

- (void)_doBackgroundUploadWithRecords:(NSArray *)records identifiers:(NSArray *)identifiers
{
    /*
     * When you make changes here, always check the server-side program will
     * accept it. The source code is at
     * https://git.rakuten-it.com/projects/RATR/repos/receiver/browse/receiver.c
     */

    typeof(self) __weak weakSelf = self;

    /*
     * Prepare the body of our POST request. It's a JSON-formatted array
     * of records. Note that the server doesn't accept pretty-formatted JSON.
     *
     * We could append 'record' NSData instances to 'postBody' in turn, separating
     * each with a comma, but we'll need an array of deserialized objects anyway
     * for using within the notifications we're sending.
     */

    NSArray *recordGroup = ({
        NSMutableArray *builder = [NSMutableArray arrayWithCapacity:records.count];
        for (NSData *recordData in records)
        {
            id object = [NSJSONSerialization JSONObjectWithData:recordData
                                                        options:0
                                                          error:NULL];
            if(object) {
                [builder addObject:object];
            }
        }
        builder.copy;
    });

    [NSNotificationCenter.defaultCenter postNotificationName:RAnalyticsWillUploadNotification
                                                      object:recordGroup];

    NSMutableData *postBody = NSMutableData.new;
    [postBody appendData:[@"cpkg_none=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[NSJSONSerialization dataWithJSONObject:recordGroup
                                                         options:0
                                                           error:NULL]];


    /*
     * Prepare and send the request.
     *
     * We only delete the records from our database if server returns a 200 HTTP status.
     */

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_endpoint
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:30];


    /*
     * For historical reasons we don't send the JSON as JSON but as some
     * weird non-urlEncoded x-www-form-urlencoded, passed as text/plain.
     *
     * The backend also doesn't accept a charset value (but assumes UTF-8).
     */

    [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];

    /*
     * Set the content length, as the backend needs it.
     */

    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postBody.length] forHTTPHeaderField:@"Content-Length"];

    request.HTTPMethod = @"POST";
    request.HTTPBody = postBody;

    NSURLSessionDataTask *dataTask = [NSURLSession.sharedSession dataTaskWithRequest:request
                                                                   completionHandler:^(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error)
                                      {
                                          typeof(weakSelf) __strong strongSelf = weakSelf;

                                          if (error)
                                          {
                                              /*
                                               * Connection failed. Request a new attempt before calling the completion.
                                               */

                                              if (strongSelf)
                                              {
                                                  @synchronized(strongSelf)
                                                  {
                                                      strongSelf.uploadRequested = YES;
                                                  }
                                              }
                                          }
                                          else if ([response isKindOfClass:NSHTTPURLResponse.class])
                                          {
                                              NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                              if (httpResponse.statusCode == 200)
                                              {
                                                  /*
                                                   * Success!
                                                   */
#if DEBUG
                                                  NSMutableString *logMessage = [NSMutableString stringWithCapacity:20];
                                                  [logMessage appendString:[NSString stringWithFormat:@"Successfully sent events to RAT from %@:",strongSelf.description]];

                                                  [recordGroup enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                                      [logMessage appendFormat:@"\n%@ %@", @(idx), obj];
                                                  }];

                                                  RAnalyticsDebugLog(@"%@", logMessage);
#endif

                                                  [NSNotificationCenter.defaultCenter postNotificationName:RAnalyticsUploadSuccessNotification
                                                                                                    object:recordGroup];

                                                  /*
                                                   * Delete the records from the local database.
                                                   */

                                                  [_database deleteBlobsWithIdentifiers:identifiers
                                                                                               in:_databaseTableName
                                                                                             then:^{
                                                                                                 // To throttle uploads, we schedule a new upload to send the rest of the records.
                                                                                                 typeof(weakSelf) __strong strongSelf = weakSelf;

                                                                                                 [strongSelf _scheduleUploadOrPerformImmediately];
                                                                                             }];
                                                  return;
                                              }

                                              error = [NSError errorWithDomain:NSURLErrorDomain
                                                                          code:NSURLErrorUnknown
                                                                      userInfo:@{NSLocalizedDescriptionKey: @"invalid_response",
                                                                                 NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"Expected status code == 200, got %ld", (long)httpResponse.statusCode]}];
                                          }

                                          id userInfo = nil;
                                          if (error)
                                          {
                                              userInfo = @{NSUnderlyingErrorKey: error};
                                          }

                                          [NSNotificationCenter.defaultCenter postNotificationName:RAnalyticsUploadFailureNotification
                                                                                            object:recordGroup
                                                                                          userInfo:userInfo];

                                          [strongSelf _backgroundUploadEnded];
                                      }];
    [dataTask resume];
}

/*
 * This method is called whenever a background upload ends, successfully or not.
 * If uploadRequested has been set, it schedules another upload.
 */

- (void)_backgroundUploadEnded
{
    @synchronized(self)
    {
        // It's time to invalidate our timer to clear the way for new uploads to get scheduled.
        [self.uploadTimer invalidate];
        self.uploadTimer = nil;

        self.zeroBatchingDelayUploadInProgress = NO;

        // If another upload has been requested, schedule it
        if (!self.uploadRequested)
        {
            return;
        }
    }

    [self _scheduleBackgroundUpload];
}

/*
 * Schedule a new background upload, if none has already been scheduled or is
 * currently being processed. Otherwise it just sets 'uploadRequested' to YES
 * so that scheduling happens next time -_backgroundUploadEnded gets called.
 */

- (void)_scheduleBackgroundUpload
{
    /*
     * REMI-1105: Using NSTimer.scheduledTimer() won't work from the background
     *            queue we're executing on. We could use NSTimer's designated
     *            initializer instead, and manually add the timer to the main
     *            run loop, but the documentation of NSRunLoop state its methods
     *            should always be called from the main thread because the class
     *            is not thread safe.
     */

    dispatch_async(dispatch_get_main_queue(), ^{

        // If a background upload has already been scheduled or is underway,
        // just set uploadRequested to YES and return
        if (self.uploadTimer.isValid)
        {
            self.uploadRequested = YES;
            return;
        }

        // If timer interval is zero and we got here it means that there is an upload in progress.
        // Therefore, schedule a timer with a 10s delay which is short-ish but long enough that the
        // in progress upload will likely complete before the timer fires.
        self.uploadTimer = [NSTimer scheduledTimerWithTimeInterval:self.uploadTimerInterval == 0 ? 10.0 : self.uploadTimerInterval
                                                            target:self
                                                          selector:@selector(_doBackgroundUpload)
                                                          userInfo:nil
                                                           repeats:NO];
        self.uploadRequested = NO;
    });
}

//--------------------------------------------------------------------------

- (void)_startNewSessionEvent
{
    /*
     * Schedule a background upload attempt when the app becomes
     * active.
     */

    // FIXME: when the LaunchCollector spools its launch/resume events, a background upload will
    // be scheduled so we possibly no longer need this here
    [self _scheduleUploadOrPerformImmediately];
}

@end
