//
//  RSDKError.m
//  RSDKSupport
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/31/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

#import "NSDictionary+RAExtensions.h"

#import "RSDKAssert.h"
#import "RSDKError.h"

NSString *const RSDKDefaultErrorDomain     = @"jp.co.rakuten.sdtd.sdk.ErrorDomain";
NSString *const RSDKErrorMessageKey        = @"RSDKMessage";
NSString *const RSDKErrorURLResponseKey    = @"RSDKResponse";
NSString *const RSDKErrorParsedObjectKey   = @"RSDKParsed";
NSString *const RSDKErrorServerResponseKey = @"RSDKData";
NSString *const RSDKErrorForwardedErrorKey = @"RSDKError";


@implementation RSDKError

#pragma mark - Initializers

+ (instancetype)errorWithError:(NSError *)error
{
    return [[self alloc] initWithError:error];
}

- (instancetype)initWithError:(NSError *)error
{
    if (!(self = [self initWithDomain:error.domain code:error.code userInfo:error.userInfo])) { return nil; }
    
    return self;
}


#pragma mark - NSMutableCopying

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [RSDKMutableError errorWithError:self];
}


#pragma mark - Utilities

- (id)objectForUserInfoKey:(NSString *)key
{
    return [self.userInfo objectForKey:key];
}


#pragma mark - Object subscripting

- (id)objectForKeyedSubscript:(id<NSCopying>)key
{
    return [self objectForUserInfoKey:(NSString *)key];
}


#pragma mark - Deprecated methods
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

+ (instancetype)errorWithCode:(NSInteger)code
                     userInfo:(NSDictionary *)userInfo
{
    NSMutableDictionary *extra = [NSMutableDictionary dictionaryWithDictionary:userInfo];
    if ([userInfo hasKey:RSDKErrorMessageKey])
    {
        extra[NSLocalizedDescriptionKey] = userInfo[RSDKErrorMessageKey];
    }
    if ([userInfo hasKey:RSDKErrorForwardedErrorKey])
    {
        extra[NSUnderlyingErrorKey] = userInfo[RSDKErrorForwardedErrorKey];
    }
    
    return [self errorWithDomain:RSDKDefaultErrorDomain
                            code:code
                        userInfo:extra];
}

+ (instancetype)errorWithCode:(NSInteger)code
                      message:(NSString *)message
                        extra:(NSDictionary *)extra
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:extra];
    if (![extra hasKey:RSDKErrorMessageKey])
    {
        if (!message)
        {
            NSString *description = [RSDKError stringForErrorCode:code];
            if (description == nil)
            {
                static NSString *const unknownError = @"Unknown error";
                description = unknownError;
            }
            
            userInfo[RSDKErrorMessageKey] = description;
        } else
        {
            userInfo[RSDKErrorMessageKey] = message;
        }
    }
    
    return [self errorWithCode:code
                      userInfo:userInfo];
}

+ (instancetype)errorWithError:(NSError *)error
                       message:(NSString *)message
                         extra:(NSDictionary *)extra
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:extra];
    if (![extra hasKey:RSDKErrorMessageKey])
    {
        userInfo[RSDKErrorMessageKey] = message ? message : [RSDKError stringForErrorCode:RSDKForwardedError];
    }
    userInfo[RSDKErrorForwardedErrorKey] = error;
    
    return [self errorWithCode:RSDKForwardedError
                      userInfo:userInfo];
}

+ (NSString *)stringForErrorCode:(NSInteger)errorCode
{
    static NSDictionary *errorStrings;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        errorStrings = @{@(RSDKForwardedError): @"Forwarded error",
                         @(RSDKGenericError):   @"Generic error"};
    });
    
    RSDKASSERTIFNOT([errorStrings hasKey:@(errorCode)], @"Invalid error code");
    
    return errorStrings[@(errorCode)];
}

#pragma clang diagnostic pop

@end


@interface _RSDKBlockRecoveryAttempter : NSObject

@property (copy, nonatomic) BOOL (^recoveryAttempterBlock)(NSError *, NSString *, NSUInteger);

@end


@interface RSDKMutableError ()

@property (strong, nonatomic) NSMutableDictionary *mutableUserInfo;

@end

@implementation RSDKMutableError

#pragma mark - Initialization

- (instancetype)initWithDomain:(NSString *)domain code:(NSInteger)code userInfo:(NSDictionary *)dict
{
    if (!(self = [super initWithDomain:domain code:code userInfo:nil])) { return nil; }
    
    _mutableUserInfo = [NSMutableDictionary dictionaryWithDictionary:dict];
    
    return self;
}


#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return [RSDKError errorWithError:self];
}


#pragma mark - User info manipulation

- (void)setObject:(id)object forUserInfoKey:(NSString *)key
{
    self.mutableUserInfo[key] = object;
}

- (void)setLocalizedDescription:(NSString *)localizedDescription
{
    self[NSLocalizedDescriptionKey] = [localizedDescription copy];
}

- (void)setLocalizedFailureReason:(NSString *)localizedFailureReason
{
    self[NSLocalizedFailureReasonErrorKey] = [localizedFailureReason copy];
}

- (void)setLocalizedRecoverySuggestion:(NSString *)localizedRecoverySuggestion
{
    self[NSLocalizedRecoverySuggestionErrorKey] = [localizedRecoverySuggestion copy];
}

- (NSDictionary *)userInfo
{
    return [self.mutableUserInfo copy];
}

- (void)setUserInfo:(NSDictionary *)userInfo
{
    if (userInfo == _mutableUserInfo || [userInfo isEqualToDictionary:_mutableUserInfo]) { return; }
    _mutableUserInfo = [userInfo mutableCopy];
}


#pragma mark - Object subscripting

- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)key
{
    [self setObject:object forUserInfoKey:(NSString *)key];
}


#pragma mark - Error recovery

- (void)setLocalizedRecoveryOptions:(NSArray *)recoveryOptions recoveryAttempter:(id)recoveryAttempter
{
    self[NSLocalizedRecoveryOptionsErrorKey] = [recoveryOptions copy];
    self[NSRecoveryAttempterErrorKey] = recoveryAttempter;
}

- (void)setLocalizedRecoveryOptions:(NSArray *)recoveryOptions recoveryAttempterBlock:(BOOL (^)(NSError *, NSString *, NSUInteger))recoveryAttempterBlock
{
    _RSDKBlockRecoveryAttempter *recoveryAttempter = [_RSDKBlockRecoveryAttempter new];
    recoveryAttempter.recoveryAttempterBlock = recoveryAttempterBlock;
    [self setLocalizedRecoveryOptions:recoveryOptions recoveryAttempter:recoveryAttempter];
}

- (void)addLocalizedRecoveryOption:(NSString *)recoveryOptionTitle recoveryAttempterBlock:(BOOL (^)())recoveryAttempterBlock
{
    NSParameterAssert(recoveryOptionTitle);
    
    NSMutableArray *mutableRecoveryOptions = [NSMutableArray arrayWithArray:self.localizedRecoveryOptions];
    [mutableRecoveryOptions addObject:recoveryOptionTitle];
    
    NSUInteger newOptionIndex = [mutableRecoveryOptions count] - 1;
    
    id previousRecoveryAttempter = [self recoveryAttempter];
    
    [self setLocalizedRecoveryOptions:mutableRecoveryOptions recoveryAttempterBlock:^BOOL(NSError *error, NSString *optionTitle, NSUInteger optionIndex) {
        if (optionIndex == newOptionIndex)
        {
            if (recoveryAttempterBlock)
            {
                return recoveryAttempterBlock();
            }
        } else if (previousRecoveryAttempter && previousRecoveryAttempter != [error recoveryAttempter]) // Prevent infinite loops
        {
            return [previousRecoveryAttempter attemptRecoveryFromError:error optionIndex:optionIndex];
        }
        
        return NO;
    }];
}

@end


@implementation _RSDKBlockRecoveryAttempter

#pragma mark - NSErrorRecoveryAttempting

- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex
{
    if (!self.recoveryAttempterBlock) { return NO; }
    
    NSArray *recoveryOptions = error.localizedRecoveryOptions;
    return self.recoveryAttempterBlock(error, recoveryOptions[recoveryOptionIndex], recoveryOptionIndex);
}

- (void)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex delegate:(id)delegate didRecoverSelector:(SEL)didRecoverSelector contextInfo:(void *)contextInfo
{
    if (!delegate) { return; }
    
    BOOL didRecover = [self attemptRecoveryFromError:error optionIndex:recoveryOptionIndex];
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[delegate methodSignatureForSelector:didRecoverSelector]];
    [invocation setTarget:delegate];
    [invocation setSelector:didRecoverSelector];
    [invocation setArgument:&didRecover atIndex:2];
    [invocation setArgument:&contextInfo atIndex:3];
    [invocation invoke];
}

@end
