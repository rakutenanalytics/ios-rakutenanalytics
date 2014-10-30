//
//  RNetworkOperaion.h
//  RSDKSupport
//
//  Created by Zachary Radke on 11/19/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

@import Foundation;

@class RNetworkCertificateAuthenticator, RNetworkOperation;
@protocol RNetworkResponseSerializer;

/**
 * An RNetworkOperation's state.
 *
 * @enum RNetworkOperationState
 * @ingroup SupportConstants
 */
typedef NS_ENUM(NSInteger, RNetworkOperationState) {

    /**
     * The operation's state has not been defined.
     */
    RNetworkOperationUndefined = 0,

    /**
     * The operation is ready to be started.
     */
    RNetworkOperationReady,

    /**
     * The operation is currently running the request.
     */
    RNetworkOperationExecuting,

    /**
     * The operation has completed, either naturally or due to cancellation.
     */
    RNetworkOperationFinished,
};


/**
 * Handle request completions.
 *
 * @ingroup SupportTypes
 * @param operation      The calling operation.
 * @param responseObject The response object, or `nil` if none is available.
 * @param error          An `NSError` object if the operation failed, or `nil` otherwise.
 * @see RNetworkOperation::setNetworkCompletionBlock:
 */
typedef void (^rnetwork_completion_block_t)(RNetworkOperation *operation, id responseObject, NSError *error);


/**
 * Handle redirection responses.
 *
 * @ingroup SupportTypes
 * @param connection       The connection currently processing the request.
 * @param request          The request being redirected.
 * @param redirectResponse The redirection response received from the server.
 * @return The block should return a new `NSURLRequest` object corresponding to the
 *         next request to initiate.
 * @see RNetworkOperation::setRedirectResponseBlock:
 */
typedef NSURLRequest* (^rredirect_response_block_t)(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse);


/**
 * Handle authentication challenges.
 *
 * @ingroup SupportTypes
 * @param connection  Connection currently processing the request.
 * @param challenge   Authentication challenge.
 * @see RNetworkOperation::setWillSendRequestForAuthenticationChallengeBlock:
 */
typedef void (^rauthentication_challenge_block_t)(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge);


/**
 * Return a cached response.
 *
 * @ingroup SupportTypes
 * @param connection      Connection currently processing the request.
 * @param cachedResponse  Response to modify.
 * @return Either `cachedResponse` or a different response.
 * @see RNetworkOperation::setCacheResponseBlock:
 */
typedef NSCachedURLResponse *(^rcache_response_block_t)(NSURLConnection *connection, NSCachedURLResponse *cachedResponse);


/**
 * Discrete network request, taken through to completion with ither a result or
 * an error.
 *
 * Since it subclasses `NSOperation`, it can be added to any `NSOperationQueue`,
 * cancelled, or started manually. It is mostly useful in applications designed
 * to support iOS versions prior to 7.0, when `NSURLSession` was introduced.
 *
 * @class RNetworkOperation RNetworkOperation.h <RSDKSupport/RNetworkOperation.h>
 */
@interface RNetworkOperation : NSOperation

/// @name Designated initializer

/**
 * The designated initializer for this class.
 *
 * The `NSURLRequest` object passed will populate the request property, but cannot be modified after
 * initializing an instance, aside from altering #inputStream.
 *
 * @param request The `NSURLRequest` to issue.
 * @return A new instance of RNetworkOperation.
 */
- (instancetype)initWithRequest:(NSURLRequest *)request;


/// @name Getting the operation's state

/// The current state of the operation
@property (assign, nonatomic, readonly) RNetworkOperationState state;


/// @name Getting network request and response properties

/// The `NSURLRequest` for this operation.
@property (strong, nonatomic, readonly) NSURLRequest *request;

/// The `NSHTTPURLResponse` when the operation finishes loading.
@property (strong, nonatomic, readonly) NSHTTPURLResponse *response;

/**
 * An object which conforms to the RNetworkResponseSerializer protocol.
 *
 * This object will be used to validate and serialize the raw `NSData` returned by the network request.
 * If no serializer is set, the raw `NSData` will populate #responseObject.
 */
@property (strong, nonatomic) id <RNetworkResponseSerializer>responseSerializer;

/// The serialized object returned from the network request.
@property (strong, nonatomic, readonly) id responseObject;

/// An error generated during the network request or serialization of the resulting data.
@property (strong, nonatomic, readonly) NSError *error;


/// @name Completion handling

/// The queue on which the completion handler will be executed. If `nil`, it will execute on the background network thread.
@property (strong, nonatomic) NSOperationQueue *completionQueue;

/**
 * Alternative to `-[NSBlockOperation setCompletionBlock:]`, with more helpful completion block parameters.
 *
 * @param networkCompletionBlock The block that will execute when the operation finishes.
 */
- (void)setNetworkCompletionBlock:(rnetwork_completion_block_t)networkCompletionBlock;


/// @name Executing in the background

/**
 * Request that the execution of this operation happens in the background.
 *
 * @param handler The expiration handler that will be executed if the
 *                operation cannot resolve in time while the application is
 *                in the background.
 */
- (void)setShouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler;


/// @name Streams

/// Proxy for the request's `-HTTPBodyStream`.
@property (strong, nonatomic) NSInputStream *inputStream;

/// Lazy loaded output stream.
@property (strong, nonatomic) NSOutputStream *outputStream;


/// @name Authentication

/**
 *  The @ref RNetworkCertificateAuthenticator to use to validate a server's trust. This allows for SSL certificate and public key pinning to improve security.
 */
@property (strong, nonatomic) RNetworkCertificateAuthenticator *certificateAuthenticator;

/**
 * The `NSURLCredential` to use when the request receives an authentication challenge.
 *
 * This credential will only attempt being used once.
 *
 * @note If #setWillSendRequestForAuthenticationChallengeBlock: is set, this credential will be
 * ignored.
 */
@property (strong, nonatomic) NSURLCredential *credential;

/**
 * This block will be called by `-[NSURLConnectionDelegate connection:willSendRequestForAuthenticationChallenge:]`.
 *
 * The block passed will be executed as many times as the connection sends the message to its
 * delegate (this operation). Properly, the block should use the passed `NSURLAuthenticationChallenge`
 * object's sender property to resolve the challenge. The block can be unset by passing `nil`. Please
 * note that this block is not manually released by the operation, so take care when using self
 * references within it if you are retaining this operation.
 *
 * @param block The block which will resolve the authentication challenge,
 *              or `nil` to remove any existing authentication challenge block.
 *
 * @note If this is set, the credential property will be ignored.
 */
- (void)setWillSendRequestForAuthenticationChallengeBlock:(rauthentication_challenge_block_t)block;


/// @name Redirection

/**
 * This block will be called by `-[NSURLConnectionDataDelegate connection:willSendRequest:redirectResponse:]`.
 *
 * The block passed will be executed as many times as the connection sends the message to its
 * delegate (this operation). Properly, the block should return the next `NSURLRequest` to make. If
 * this block is not set, the redirection request will be returned without any changes. The block can
 * be unset by passing `nil`.
 *
 * @note This block is not manually released by this operation,
 *       so take care using self references when retaining this operation.
 *
 * @param block The block which will resolve the redirection, or `nil` to remove any existing
 *              redirection block.
 */
- (void)setRedirectResponseBlock:(rredirect_response_block_t)block;


/// @name Caching

/**
 * This method will be called by `-[NSURLConnectionDataDelegate connection:willCacheResponse:]`.
 *
 * The block passed should return an `NSCachedURLResponse` object modified as needed. If this block is
 * not set, `cachedResponse` will be returned immediately as is. The block can be unset by passing `nil` to this method.
 *
 * @note This block is not manually released by the operation, so take care using self references when retaining this operation.
 *
 * @param block The block which will return a cached response, or `nil` to remove any existing caching block.
 */
- (void)setCacheResponseBlock:(rcache_response_block_t)block;


/// @name Callbacks

/**
 * Set the upload progress callback block.
 *
 * @note This block is not manually released by the operation, so take care using self references when retaining this operation.
 *
 * @param block The upload progress block which will be executed whenever data is sent, or `nil` to
 *              unset any existing upload progress block.
 *
 * @note The block passed is executed on the main queue.
 */
- (void)setUploadProgressBlock:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block;

/**
 * Set the download progress callback block.
 *
 * @note This block is not manually released by the operation, so take care using self references when retaining this operation.
 *
 * @param block The download progress block which will be executed whenever data is received, or `nil`
 *              to unset any existing download progress block
 */
- (void)setDownloadProgressBlock:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))block;

@end
