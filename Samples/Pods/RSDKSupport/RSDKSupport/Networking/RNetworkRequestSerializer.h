//
//  RNetworkRequestSerializer.h
//  RSDKSupport
//
//  Created by Zachary Radke on 11/19/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

@import Foundation;

/**
 * This protocol provides a baseline for request serializers that can be
 * used to make `NSURLRequest`s more friendly to work with. A single concrete implementation is
 * provided, @ref RNetworkRequestSerializer.
 *
 * Implementers of this protocol should use the passed `NSURLRequest` and parameters to generate a new
 * `NSURLRequest`. An optional error pointer is provided to capture request serialization errors that
 * might occur.
 *
 * @protocol RNetworkRequestSerializer RNetworkRequestSerializer.h <RSDKSupport/RNetworkRequestSerializer.h>
 */
@protocol RNetworkRequestSerializer <NSObject>
@required

/**
 * Method which transforms parameters and an existing `NSURLRequest` into a new one.
 *
 * @param request The original `NSURLRequest` to be used as a base.
 * @param parameters An object which contains parameters to encode in the `NSURLRequest`.
 * @param error An optional pointer to an `NSError` which can capture serialization errors.
 */
- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request withParameters:(id)parameters error:(NSError **)error;

@end


/**
 * A concrete implementation of the @ref RNetworkRequestSerializer-p protocol which handles URI and form-
 * data serialization.
 *
 * @class RNetworkRequestSerializer RNetworkRequestSerializer.h <RSDKSupport/RNetworkRequestSerializer.h>
 */
@interface RNetworkRequestSerializer : NSObject <RNetworkRequestSerializer>

/// @name Generating a new serializer

/**
 * Factory method which creates a new serializer.
 *
 * @return A new instance of the receiver.
 */
+ (instancetype)serializer;


/// @name Configuring serialization

/// The encoding to use when serializing parameters
@property (assign, nonatomic) NSStringEncoding stringEncoding;

/**
 * A set of HTTP methods in which parameters should be encoded in the URI.
 *
 * This set defaults to:
 * - `GET`
 * - `HEAD`
 * - `DELETE`
 *
 * If a request is passed with a matching `HTTPMethod` property, the parameters will be encoded as a query
 * string and appended to the request's URL. Otherwise, it will be set to the request's `HTTPBody`.
 */
@property (strong, nonatomic) NSSet *URIEncodedHTTPMethods;


/// @name HTTP headers

/**
 * The serializer's registered headers.
 *
 * @return An `NSDictionary` of set headers.
 */
- (NSDictionary *)requestHeaders;

/**
 * Registers a header for this serializer to use on incoming `NSURLRequest`s.
 *
 * @param value The value of the header.
 * @param field The header field.
 */
- (void)setValue:(NSString *)value forHeaderField:(NSString *)field;


/// @name Custom query serialization

/**
 * Allows the custom serialization of parameters into a string through the block
 *
 * The block passed should convert the given parameters into an `NSString` which can be used as a URI
 * query string or form data string. The block can optionally be passed an `NSError` pointer which can
 * be used to contain serialization errors. If this block is not set, the default encoding will be
 * used. To unset the block, pass `nil` to this method. Please note that this block is not manually
 * released by this instance, so take care when using self references and retaining this instance
 * to avoid retain loops.
 *
 * @param block The block which serializes the parameters into a string, or `nil` to unset any existing
 * serialization block.
 */
- (void)setQuerySerializationBlock:(NSString *(^)(NSURLRequest *request, id parameters, NSError * __autoreleasing *error))block;


/// @name Convenience request generation

/**
 * Method to quickly generate a serialized request with a given method and URL string.
 *
 * @param method The HTTP method to use for the new request.
 * @param URLString The string representation fo the URL for the new request.
 * @param parameters Parameters to be encoded in the new request, either in the URI or body.
 *
 * @return A new `NSURLRequest` instance.
 */
- (NSURLRequest *)requestWithMethod:(NSString *)method URLString:(NSString *)URLString parameters:(id)parameters;

/**
 *  Method to quickly generate a serialized request given a method, URL, and timeout interval.
 *
 *  @param method     The HTTP method to use for the new request.
 *  @param URL        The URL for the new request.
 *  @param parameters Parameters to be encoded in the new request.
 *  @param timeout    The timeout interval to use in the new request.
 *
 *  @return A new `NSURLRequest` instance.
 */
- (NSURLRequest *)requestWithMethod:(NSString *)method URL:(NSURL *)URL parameters:(id)parameters timeout:(NSTimeInterval)timeout;
@end
