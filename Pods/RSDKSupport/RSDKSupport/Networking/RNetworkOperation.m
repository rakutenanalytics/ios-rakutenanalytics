//
//  RNetworkOperaion.m
//  RSDKSupport
//
//  Created by Zachary Radke on 11/19/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//
//  Copied shamelessly from https://github.com/AFNetworking/AFNetworking

@import UIKit;

#import "RNetworkOperation.h"
#import "RNetworkResponseSerializer.h"
#import "RNetworkCertificateAuthenticator.h"

static inline NSString *RNetworkKeyPathFromOperationState(RNetworkOperationState state)
{
    switch (state)
    {
        case RNetworkOperationReady:
            return NSStringFromSelector(@selector(isReady));
        case RNetworkOperationExecuting:
            return NSStringFromSelector(@selector(isExecuting));
        case RNetworkOperationFinished:
            return NSStringFromSelector(@selector(isFinished));
        default:
            return NSStringFromSelector(@selector(state));
    }
}

@interface RNetworkOperation () <NSURLConnectionDataDelegate>

@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSRecursiveLock *lock;

@property (assign, nonatomic, readwrite) RNetworkOperationState state;
@property (strong, nonatomic, readwrite) NSURLRequest *request;
@property (strong, nonatomic, readwrite) NSHTTPURLResponse *response;
@property (strong, nonatomic, readwrite) id responseObject;
@property (strong, nonatomic, readwrite) NSError *error;

@property (copy, nonatomic) rauthentication_challenge_block_t willSendRequestForAuthenticationChallengeBlock;
@property (copy, nonatomic) rredirect_response_block_t        redirectResponseBlock;
@property (copy, nonatomic) rcache_response_block_t           cacheResponseBlock;

@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (assign, nonatomic) long long totalBytesRead;
@property (copy, nonatomic) void (^uploadProgressBlock)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite);
@property (copy, nonatomic) void (^downloadProgressBlock)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead);

@end

@implementation RNetworkOperation

@synthesize outputStream = _outputStream;

+ (void)networkThreadStart:(id)__unused context
{
    @autoreleasepool
    {
        [[NSThread currentThread] setName:@"jp.co.rakuten.sdk.networkOperation.thread"];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)networkThread
{
    static NSThread *networkThread;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkThreadStart:) object:nil];
        [networkThread start];
    });
    
    return networkThread;
}

- (instancetype)initWithRequest:(NSURLRequest *)request
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    self.request = request;
    
    self.lock = [NSRecursiveLock new];
    self.lock.name = [NSString stringWithFormat:@"jp.co.rakuten.sdk.networkOperation.lock.%p", self];
    
    self.state = RNetworkOperationReady;
    
    return self;
}

- (id)init
{
    return [self initWithRequest:nil];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, state: %@, cancelled: %@, request: %@, response: %@>", NSStringFromClass(self.class), self, RNetworkKeyPathFromOperationState(self.state), self.isCancelled ? @"YES" : @"NO", self.request, self.response];
}


#pragma mark - NSOperation Subclass

- (void)start
{
    [self.lock lock];
    
    if (self.isReady)
    {
        self.state = RNetworkOperationExecuting;
        [self performSelector:@selector(startConnection) onThread:[[self class] networkThread] withObject:nil waitUntilDone:NO];
    }
    
    [self.lock unlock];
}

- (void)startConnection
{
    [self.lock lock];
    
    if (!self.isCancelled)
    {
        self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [self.connection scheduleInRunLoop:runLoop forMode:NSRunLoopCommonModes];
        [self.outputStream scheduleInRunLoop:runLoop forMode:NSRunLoopCommonModes];
        
        [self.connection start];
    }
    
    [self.lock unlock];
}

- (void)cancel
{
    [self.lock lock];
    
    if (!self.isFinished && !self.isCancelled)
    {
        [super cancel];
        
        if (self.isExecuting)
        {
            [self performSelector:@selector(cancelConnection) onThread:[[self class] networkThread] withObject:nil waitUntilDone:NO];
        }
    }
    
    [self.lock unlock];
}

- (void)cancelConnection
{
    NSDictionary *userInfo = nil;
    if (self.request.URL)
    {
        userInfo = @{NSURLErrorFailingURLErrorKey: self.request.URL};
    }
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
    
    if (!self.isFinished)
    {
        if (self.connection)
        {
            [self.connection cancel];
            [self connection:self.connection didFailWithError:error];
        }
        else
        {
            self.error = error;
            [self finish];
        }
    }
}

- (void)finish
{
    self.state = RNetworkOperationFinished;
    self.connection = nil;
}

- (BOOL)isConcurrent
{
    return YES;
}


#pragma mark - State management

- (BOOL)isTransitionValid:(RNetworkOperationState)toState
{
    RNetworkOperationState fromState = self.state;
    
    switch (fromState)
    {
        case RNetworkOperationReady:
        {
            if (toState == RNetworkOperationExecuting)
            {
                return YES;
            } else if (toState == RNetworkOperationFinished)
            {
                return self.isCancelled;
            } else
            {
                return NO;
            }
        }
        case RNetworkOperationExecuting:
            return toState == RNetworkOperationFinished;
            
        case RNetworkOperationFinished:
            return NO;
            
        default:
            return YES;
    }
    
    return YES;
}

- (void)setState:(RNetworkOperationState)state
{
    if (![self isTransitionValid:state]) { return; }
    
    [self.lock lock];
    
    NSString *oldStateKey = RNetworkKeyPathFromOperationState(self.state);
    NSString *newStateKey = RNetworkKeyPathFromOperationState(state);
    
    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    
    _state = state;
    
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
    
    [self.lock unlock];
}

- (BOOL)isReady
{
    return (self.state == RNetworkOperationReady) && [super isReady];
}

- (BOOL)isExecuting
{
    return self.state == RNetworkOperationExecuting;
}

- (BOOL)isFinished
{
    return self.state == RNetworkOperationFinished;
}


#pragma mark - Completion block management

- (void)setCompletionBlock:(void (^)(void))block
{
    [self.lock lock];
    
    if (!block) { [super setCompletionBlock:nil]; }
    
    __weak typeof(self) weakSelf = self;
    [super setCompletionBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (strongSelf.completionQueue)
        {
            [strongSelf.completionQueue addOperationWithBlock:^{
                block();
                [strongSelf setCompletionBlock:nil];
            }];
        }
        else
        {
            block();
            [strongSelf setCompletionBlock:nil];
        }
    }];
    
    [self.lock unlock];
}

- (void)setNetworkCompletionBlock:(rnetwork_completion_block_t)networkCompletionBlock
{
    __weak typeof(self) weakSelf = self;
    [self setCompletionBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (networkCompletionBlock)
        {
            networkCompletionBlock(strongSelf, strongSelf.responseObject, strongSelf.error);
        }
    }];
}


#pragma mark - Background execution

- (void)setShouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler
{
    [self.lock lock];
    
    if (!self.backgroundTaskIdentifier)
    {
        __weak typeof(self) weakSelf = self;
        
        self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            if (handler) { handler(); }
            
            [strongSelf cancel];
            
            [[UIApplication sharedApplication] endBackgroundTask:strongSelf.backgroundTaskIdentifier];
            strongSelf.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];
    }
    
    [self.lock unlock];
}


#pragma mark - Stream management

- (NSInputStream *)inputStream
{
    return self.request.HTTPBodyStream;
}

- (void)setInputStream:(NSInputStream *)inputStream
{
    [self.lock lock];
    
    [self willChangeValueForKey:NSStringFromSelector(@selector(inputStream))];
    
    NSMutableURLRequest *mutableRequest = [self.request mutableCopy];
    mutableRequest.HTTPBodyStream = inputStream;
    self.request = mutableRequest;
    
    [self didChangeValueForKey:NSStringFromSelector(@selector(inputStream))];
    
    [self.lock unlock];
}

- (NSOutputStream *)outputStream
{
    if (!_outputStream)
    {
        [self setOutputStream:[NSOutputStream outputStreamToMemory]];
    }
    
    return _outputStream;
}

- (void)setOutputStream:(NSOutputStream *)outputStream
{
    [self.lock lock];
    
    if (outputStream != _outputStream)
    {
        [self willChangeValueForKey:NSStringFromSelector(@selector(outputStream))];
        
        if (_outputStream)
        {
            [_outputStream close];
        }
        
        _outputStream = outputStream;
        
        [self didChangeValueForKey:NSStringFromSelector(@selector(outputStream))];
    }
    
    [self.lock unlock];
}


#pragma mark - NSURLConnectionDelegate and NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (self.willSendRequestForAuthenticationChallengeBlock)
    {
        self.willSendRequestForAuthenticationChallengeBlock(connection, challenge);
        return;
    }
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        if (!self.certificateAuthenticator || [self.certificateAuthenticator validateServerTrust:challenge.protectionSpace.serverTrust])
        {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
        } else
        {
            [challenge.sender cancelAuthenticationChallenge:challenge];
        }
        return;
    }
    
    if (challenge.previousFailureCount == 0 && self.credential)
    {
        [challenge.sender useCredential:self.credential forAuthenticationChallenge:challenge];
    } else
    {
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if (self.redirectResponseBlock)
    {
        return self.redirectResponseBlock(connection, request, response);
    } else
    {
        return request;
    }
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (self.uploadProgressBlock)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.uploadProgressBlock(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        }];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.response = (NSHTTPURLResponse *)response;
    [self.outputStream open];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    if (self.cacheResponseBlock)
    {
        return self.cacheResponseBlock(connection, cachedResponse);
    } else
    {
        return cachedResponse;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSUInteger length = data.length;
    
    if (self.outputStream.hasSpaceAvailable)
    {
        NSInteger bytesWritten = 0;
        NSInteger totalBytesWritten = 0;
        
        do
        {
            bytesWritten = [self.outputStream write:[data bytes] maxLength:length];
            
            if (bytesWritten == -1)
            {
                [self.connection cancel];
                [self connection:connection didFailWithError:self.outputStream.streamError];
                return;
                
            } else
            {
                totalBytesWritten += bytesWritten;
            }
            
        } while (totalBytesWritten > length);
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.totalBytesRead += length;
        
        if (self.downloadProgressBlock)
        {
            self.downloadProgressBlock(length, self.totalBytesRead, self.response.expectedContentLength);
        }
    }];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSData *responseData = [self.outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [self.outputStream close];
    
    if (self.responseSerializer)
    {
        NSError *serializationError = nil;
        self.responseObject = [self.responseSerializer responseObjectForResponse:self.response data:responseData error:&serializationError];
        self.error = serializationError;
        
    } else
    {
        self.responseObject = responseData;
    }
    
    
    [self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.outputStream close];
    self.error = error;
    [self finish];
}

@end
