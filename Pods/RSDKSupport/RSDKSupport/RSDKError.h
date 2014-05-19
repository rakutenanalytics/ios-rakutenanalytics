//
//  RSDKError.h
//  RSDKSupport
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/31/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "REnumHelpers.h"

/**
 * Rakuten SDK default error domain
 */
extern NSString *const RSDKDefaultErrorDomain;

/**
 * Message key for error objects.
 */
extern NSString *const RSDKErrorMessageKey DEPRECATED_MSG_ATTRIBUTE("Please use NSLocalizedDescriptionKey instead");

/**
 * Extra key for URL response objects.
 */
extern NSString *const RSDKErrorURLResponseKey DEPRECATED_MSG_ATTRIBUTE("Please use NSURLErrorFailingURLErrorKey instead");

/**
 * Extra key for JSON parsed objects.
 */
extern NSString *const RSDKErrorParsedObjectKey;

/**
 * Extra key for raw server response data.
 */
extern NSString *const RSDKErrorServerResponseKey;

/**
 * Extra key for forwarded errors.
 */
extern NSString *const RSDKErrorForwardedErrorKey DEPRECATED_MSG_ATTRIBUTE("Please use NSUnderlyingErrorKey instead");

/**
 * Error codes.
 */
typedef NS_ENUM(NSInteger, RSDKCommonErrors)
{
    /**
     *  Generic error code.
     */
    RSDKGenericError = 1000,
    /**
     *  Forwarded error code.
     */
    RSDKForwardedError
};


/**
 * Enhancement to the NSError class with a mutable copy option and convenience methods for accessing the user info.
 */
@interface RSDKError : NSError <NSMutableCopying>

/**
 *  Factory method for generating an error from another error
 *
 *  @param error The error to initialize from. This must not be nil.
 *
 *  @return A new instance of the receiver
 */
+ (instancetype)errorWithError:(NSError *)error;

/**
 *  Initializer for generating an error from another error
 *
 *  @param error The error to initialize from. This must not be nil.
 *
 *  @return A new instance of the receiver
 */
- (instancetype)initWithError:(NSError *)error;

/**
 *  Convenience method for accessing user info values
 *
 *  @param key The key to lookup in the user info dictionary
 *
 *  @return An object associated with the key in the user info dictionary
 */
- (id)objectForUserInfoKey:(NSString *)key;

/**
 *  Convenience method for allowing subscripting with this class
 *
 *  @param key The key to lookup. This will be forwarded to the user info dictionary.
 *
 *  @return The value associated with the key in the user info dictionary
 */
- (id)objectForKeyedSubscript:(id <NSCopying>)key;

@end

/**
 *  Deprecated methods in RSDKError. These should be avoided or removed when possible, as they will be removed in future versions of the module.
 */
@interface RSDKError (Deprecated)

+ (instancetype)errorWithCode:(NSInteger)code message:(NSString *)message extra:(NSDictionary *)extra DEPRECATED_MSG_ATTRIBUTE("Please use the recommended initializers instead");
+ (instancetype)errorWithError:(NSError *)error message:(NSString *)message extra:(NSDictionary *)extra DEPRECATED_MSG_ATTRIBUTE("Please use the recommended initializers instead");
+ (NSString *)stringForErrorCode:(NSInteger)errorCode DEPRECATED_MSG_ATTRIBUTE("Please use localized strings instead");

@end


/**
 *  A mutable variant of the RSDKError class, providing convenience methods for setting user info values as well as recovery handling.
 */
@interface RSDKMutableError : RSDKError

/**
 *  Convenience setter for the NSLocalizedDescriptionKey
 *
 *  @param localizedDescription A description of the error that occured
 */
- (void)setLocalizedDescription:(NSString *)localizedDescription;

/**
 *  Convenience setter for the NSLocalizedFailureReasonKey
 *
 *  @param localizedFailureReason An explanation of the error's cause
 */
- (void)setLocalizedFailureReason:(NSString *)localizedFailureReason;

/**
 *  Convenience setter for the NSLocalizedRecoverySuggestionKey
 *
 *  @param localizedRecoverySuggestion A suggestion of how the error might be recovered.
 */
- (void)setLocalizedRecoverySuggestion:(NSString *)localizedRecoverySuggestion;

/**
 *  Mutable setter for the user info of the error
 *
 *  @param userInfo The new user info dictionary to associate with this error
 */
- (void)setUserInfo:(NSDictionary *)userInfo;

/**
 *  Convenience setter for a key in the user info dictionary.
 *
 *  @param object The object to associate with the given key
 *  @param key    The key to set in the user info dictionary
 */
- (void)setObject:(id)object forUserInfoKey:(NSString *)key;

/**
 *  Convenience setter for object subscripting.
 *
 *  @param object The object to associate with the given key
 *  @param key    The key to set in the user info dictionary
 */
- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)key;

/**
 *  Convenience setter for the NSLocalizedRecoveryOptionsKey and NSRecoveryAttempterErrorKey
 *
 *  @param recoveryOptions   An array of recovery option titles
 *  @param recoveryAttempter An object which conforms to the informal NSErrorRecoveryAttempting protocol, which can be used to attempt recovery from the error
 */
- (void)setLocalizedRecoveryOptions:(NSArray *)recoveryOptions recoveryAttempter:(id)recoveryAttempter;

/**
 *  Adds a block based recovery attempter to the error and sets the associated recovery options
 *
 *  @param recoveryOptions        An array of recovery option titles
 *  @param recoveryAttempterBlock A block that handles the error with the provided recovery option and returns a BOOL indicating whether the recovery succeeded or not
 */
- (void)setLocalizedRecoveryOptions:(NSArray *)recoveryOptions recoveryAttempterBlock:(BOOL (^)(NSError *error, NSString *recoveryOptionTitle, NSUInteger recoveryOptionIndex))recoveryAttempterBlock;

/**
 *  Adds a single recovery option to the existing recovery options with a block specifically invoked when that recovery option is selected. This method will overwrite any existing recovery attempter, but will retain the previous recovery attempter privately in the case that another option other than the newly added one is selected.
 *
 *  @param recoveryOptionTitle    The title of the recovery option to add. This must not be nil.
 *  @param recoveryAttempterBlock A block which is invoked when the new recovery option is selected that returns a BOOL indicating whether recovery succeeded or failed. This can be nil, but in its absence the option will automatically be assumed to fail.
 */
- (void)addLocalizedRecoveryOption:(NSString *)recoveryOptionTitle recoveryAttempterBlock:(BOOL (^)())recoveryAttempterBlock;

@end
