#import "MockedDatabase.h"

@implementation CurrentPage
@end

@implementation MockedDatabase

- (instancetype)init
{
    if ((self = [super init]))
    {
        _keys = NSMutableOrderedSet.new;
        _rows = NSMutableDictionary.new;
    }
    return self;
}

- (void)insertBlob:(NSData *)blob into:(NSString *)table limit:(NSUInteger)maximumNumberOfBlobs then:(dispatch_block_t)completion {
    return [self insertBlobs:@[blob] into:table limit:maximumNumberOfBlobs then:completion];
}

- (void)insertBlobs:(NSArray<NSData *> *)blobs
               into:(NSString *)table
              limit:(NSUInteger)maximumNumberOfBlobs
               then:(dispatch_block_t)completion
{
    for (NSData *blob in blobs)
    {
        static unsigned row = 0;

        NSNumber *key = @(++row);
        [_keys addObject:key];
        _rows[key] = blob.copy;
        _latestAddedJSON = [NSJSONSerialization JSONObjectWithData:blob options:0 error:0];
    }

    if (completion)
    {
        NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:completion];
        });
    }
}

- (void)fetchBlobs:(NSUInteger)maximumNumberOfBlobs
              from:(NSString *)table
              then:(void (^)(NSArray<NSData *> * _Nullable, NSArray<NSNumber *> * _Nullable))completion
{
    NSMutableArray *blobs       = NSMutableArray.new;
    NSMutableArray *identifiers = NSMutableArray.new;

    NSArray *keys = _keys.array;
    if (keys.count)
    {
        keys = [keys subarrayWithRange:NSMakeRange(0, MIN(keys.count, maximumNumberOfBlobs))];
        for (NSNumber *key in keys)
        {
            [identifiers addObject:key];
            [blobs       addObject:_rows[key]];
        }
    }

    if (completion)
    {
        NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:^{
                completion(blobs.count ? blobs : nil, identifiers.count ? identifiers : nil);
            }];
        });
    }
}

- (void)deleteBlobsWithIdentifiers:(NSArray<NSNumber *> *)identifiers
                                in:(NSString *)table
                              then:(dispatch_block_t)completion
{
    [_keys removeObjectsInArray:identifiers];
    [_rows removeObjectsForKeys:identifiers];

    if (completion)
    {
        NSOperationQueue * __weak callerQueue = NSOperationQueue.currentQueue;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            typeof(callerQueue) __strong queue = callerQueue;
            [queue addOperationWithBlock:completion];
        });
    };
}

@end
