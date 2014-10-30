//
//  RNetworkBaseClient.m
//  RSDKSupport
//
//  Created by Zachary Radke on 1/10/14.
//  Copyright (c) 2014 Rakuten Inc. All rights reserved.
//

@import ObjectiveC.runtime;

#import "RNetworkBaseClient.h"
#import "RNetworkOperation.h"
#import "RNetworkCertificateAuthenticator.h"
#import "RNetworkResponseSerializer.h"
#import "RNetworkRequestSerializer.h"

static void *RSDKSupportNetworkSharedClientKey = &RSDKSupportNetworkSharedClientKey;

NSTimeInterval const kRNetworkBaseClientDefaultTimeout = 15.0;

@interface RNetworkBaseClient ()
@property (strong, nonatomic) NSOperationQueue *queue;
@end

@implementation RNetworkBaseClient

+ (instancetype)sharedClient
{
    id sharedClient = objc_getAssociatedObject(self, RSDKSupportNetworkSharedClientKey);
    
    if (sharedClient) { return sharedClient; }
    
    @synchronized(self)
    {
        sharedClient = [self client];
        objc_setAssociatedObject(self, RSDKSupportNetworkSharedClientKey, sharedClient, OBJC_ASSOCIATION_RETAIN);
    }
    
    return sharedClient;
}

+ (instancetype)client
{
    return [self new];
}

- (instancetype)initWithBaseURL:(NSURL *)baseURL
{
    if (!(self = [super init])) { return nil; }
    
    _baseURL = baseURL;
    _queue = [NSOperationQueue new];
    
    _sharedTimeout = kRNetworkBaseClientDefaultTimeout;
    _sharedRequestSerializer = [RNetworkRequestSerializer serializer];
    _sharedResponseSerializer = [RNetworkResponseSerializer serializer];
    
    return self;
}

- (instancetype)init
{
    return [self initWithBaseURL:nil];
}


#pragma mark - Enqueueing requests

- (BOOL)queueNetworkOperation:(RNetworkOperation *)networkOperation
{
    if (networkOperation.isCancelled || networkOperation.isExecuting)
    {
        return NO;
    }
    
    [self.queue addOperation:networkOperation];
    
    return YES;
}


#pragma mark - Issuing requests

- (RNetworkOperation *)networkOperationWithRequest:(NSURLRequest *)request completionBlock:(void (^)(RNetworkOperation *, id, NSError *))completionBlock
{
    RNetworkOperation *networkOperation = [[RNetworkOperation alloc] initWithRequest:request];
    [networkOperation setNetworkCompletionBlock:completionBlock];
    
    networkOperation.credential = self.sharedCredential;
    networkOperation.certificateAuthenticator = self.sharedCertificateAuthenticator;
    networkOperation.responseSerializer = self.sharedResponseSerializer;
    networkOperation.completionQueue = self.sharedCompletionQueue;
    
    [self queueNetworkOperation:networkOperation];
    
    return networkOperation;
}

- (RNetworkOperation *)GET:(NSString *)URLPath parameters:(id)parameters completionBlock:(void (^)(RNetworkOperation *, id, NSError *))completionBlock
{
    return [self _networkOperationWithMethod:@"GET" URLPath:URLPath parameters:parameters completionBlock:completionBlock];
}

- (RNetworkOperation *)HEAD:(NSString *)URLPath parameters:(id)parameters completionBlock:(void (^)(RNetworkOperation *, id, NSError *))completionBlock
{
    return [self _networkOperationWithMethod:@"HEAD" URLPath:URLPath parameters:parameters completionBlock:completionBlock];
}

- (RNetworkOperation *)POST:(NSString *)URLPath parameters:(id)parameters completionBlock:(void (^)(RNetworkOperation *, id, NSError *))completionBlock
{
    return [self _networkOperationWithMethod:@"POST" URLPath:URLPath parameters:parameters completionBlock:completionBlock];
}

- (RNetworkOperation *)PUT:(NSString *)URLPath parameters:(id)parameters completionBlock:(void (^)(RNetworkOperation *, id, NSError *))completionBlock
{
    return [self _networkOperationWithMethod:@"PUT" URLPath:URLPath parameters:parameters completionBlock:completionBlock];
}

- (RNetworkOperation *)DELETE:(NSString *)URLPath parameters:(id)parameters completionBlock:(void (^)(RNetworkOperation *, id, NSError *))completionBlock
{
    return [self _networkOperationWithMethod:@"DELETE" URLPath:URLPath parameters:parameters completionBlock:completionBlock];
}


#pragma mark - Private utilities

- (RNetworkOperation *)_networkOperationWithMethod:(NSString *)HTTPMethod URLPath:(NSString *)URLPath parameters:(id)parameters completionBlock:(void (^)(RNetworkOperation *, id, NSError*))completionBlock
{
    NSURL *URL = [self.baseURL URLByAppendingPathComponent:URLPath];
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:self.sharedTimeout];
    mutableRequest.HTTPMethod = HTTPMethod;
    
    NSError *serializationError;
    NSURLRequest *request = [self.sharedRequestSerializer requestBySerializingRequest:mutableRequest withParameters:parameters error:&serializationError];
    if (!request)
    {
        if (completionBlock) { completionBlock(nil, nil, serializationError); }
        return nil;
    }
    
    return [self networkOperationWithRequest:request completionBlock:completionBlock];
}

@end
