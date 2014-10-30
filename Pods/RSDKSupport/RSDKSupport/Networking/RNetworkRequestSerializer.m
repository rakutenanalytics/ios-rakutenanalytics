//
//  RNetworkRequestSerializer.m
//  RSDKSupport
//
//  Created by Zachary Radke on 11/19/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//
//  Copied shamelessly from https://github.com/AFNetworking/AFNetworking

#import "RNetworkRequestSerializer.h"

static NSString *const kRValidCharactersToEscapeInQueryString = @":/?&=;+!@#$()',*";

@interface RQueryComponent : NSObject

@property (strong, nonatomic) id key;
@property (strong, nonatomic) id value;

- (instancetype)initWithKey:(id)key value:(id)value;
+ (NSArray *)arrayOfComponentsForKey:(NSString *)key value:(id)value;

- (NSString *)queryStringValueWithEncoding:(NSStringEncoding)encoding;

@end

@implementation RQueryComponent

- (instancetype)initWithKey:(id)key value:(id)value
{
    if (!(self = [super init])) { return nil; }
    
    _key = key;
    _value = value;
    
    return self;
}

+ (NSArray *)arrayOfComponentsForKey:(NSString *)key value:(id)value
{
    NSMutableArray *queryComponents = [NSMutableArray array];
    
    if ([value isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dictionary = value;
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        NSArray *sortedDictionaryKeys = [[dictionary allKeys] sortedArrayUsingDescriptors:@[sortDescriptor]];
        
        id nestedValue = nil;
        for (id nestedKey in sortedDictionaryKeys)
        {
            nestedValue = [dictionary objectForKey:nestedKey];
            if (nestedValue)
            {
                NSString *recursiveKey = key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey;
                [queryComponents addObjectsFromArray:[self arrayOfComponentsForKey:recursiveKey value:nestedValue]];
            }
        }
        
    } else if ([value isKindOfClass:[NSArray class]])
    {
        NSArray *array = value;
        
        for (id nestedValue in array)
        {
            NSString *recursiveKey = key ? [NSString stringWithFormat:@"%@[]", key] : nil;
            [queryComponents addObjectsFromArray:[self arrayOfComponentsForKey:recursiveKey value:nestedValue]];
        }
        
    } else if ([value isKindOfClass:[NSSet class]])
    {
        NSSet *set = value;
        
        for (id nestedValue in set)
        {
            [queryComponents addObjectsFromArray:[self arrayOfComponentsForKey:key value:nestedValue]];
        }
    } else
    {
        [queryComponents addObject:[[self alloc] initWithKey:key value:value]];
    }
    
    return [queryComponents copy];
}

- (NSString *)escapedQueryKeyWithEncoding:(NSStringEncoding)encoding
{
    static NSString *const kRCharactersToLeaveUnescapedInQueryStringKey = @".[]";
    
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)[self.key description], (__bridge CFStringRef)kRCharactersToLeaveUnescapedInQueryStringKey, (__bridge CFStringRef)kRValidCharactersToEscapeInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

- (NSString *)escapedQueryValueWithEncoding:(NSStringEncoding)encoding;
{
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)[self.value description], NULL, (__bridge CFStringRef)kRValidCharactersToEscapeInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

- (NSString *)queryStringValueWithEncoding:(NSStringEncoding)encoding
{
    if (!self.value || self.value == [NSNull null])
    {
        return [self escapedQueryKeyWithEncoding:encoding];
        
    } else if (!self.key)
    {
        return [self escapedQueryValueWithEncoding:encoding];
        
    } else
    {
        return [NSString stringWithFormat:@"%@=%@", [self escapedQueryKeyWithEncoding:encoding], [self escapedQueryValueWithEncoding:encoding]];
    }
}

@end


@interface RNetworkRequestSerializer ()

@property (strong, nonatomic) NSMutableDictionary *mutableRequestHeaders;
@property (copy, nonatomic) NSString *(^querySerializationBlock)(NSURLRequest *request, id parameters, NSError **error);

@end

@implementation RNetworkRequestSerializer

+ (instancetype)serializer
{
    return [self new];
}

- (instancetype)init
{
    if (!(self = [super init])) { return nil; }
    
    _stringEncoding = NSUTF8StringEncoding;
    _mutableRequestHeaders = [NSMutableDictionary dictionary];
    _URIEncodedHTTPMethods = [NSSet setWithObjects:@"GET", @"HEAD", @"DELETE", nil];
    
    return self;
}

- (NSDictionary *)requestHeaders
{
    return [self.mutableRequestHeaders copy];
}

- (void)setValue:(NSString *)value forHeaderField:(NSString *)field
{
    [self.mutableRequestHeaders setObject:value forKey:field];
}

- (NSURLRequest *)requestWithMethod:(NSString *)method URLString:(NSString *)URLString parameters:(id)parameters
{
    NSURL *url = [NSURL URLWithString:URLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    if (method)
    {
        request.HTTPMethod = method;
    }

    return [self requestBySerializingRequest:request withParameters:parameters error:NULL];
}

- (NSURLRequest *)requestWithMethod:(NSString *)method URL:(NSURL *)URL parameters:(id)parameters timeout:(NSTimeInterval)timeout
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:timeout];

    if (method)
    {
        request.HTTPMethod = method;
    }

    return [self requestBySerializingRequest:request withParameters:parameters error:NULL];
}

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request withParameters:(id)parameters error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    
    for (NSString *field in self.mutableRequestHeaders)
    {
        if (![mutableRequest valueForHTTPHeaderField:field])
        {
            [mutableRequest setValue:self.mutableRequestHeaders[field] forHTTPHeaderField:field];
        }
    }
    
    if (!parameters) { return [mutableRequest copy]; }
    
    NSString *queryString = nil;
    if (self.querySerializationBlock)
    {
        queryString = self.querySerializationBlock([mutableRequest copy], parameters, error);
    } else
    {
        NSArray *queryComponents = [RQueryComponent arrayOfComponentsForKey:nil value:parameters];
        NSMutableArray *queryFragments = [NSMutableArray arrayWithCapacity:queryComponents.count];
        for (RQueryComponent *component in queryComponents)
        {
            NSString *fragment = [component queryStringValueWithEncoding:self.stringEncoding];
            if (fragment) { [queryFragments addObject:fragment]; }
        }
        queryString = [queryFragments componentsJoinedByString:@"&"];
    }
    
    if ([self.URIEncodedHTTPMethods containsObject:mutableRequest.HTTPMethod.uppercaseString])
    {
        NSMutableString *URLStringWithParameters = [[mutableRequest.URL absoluteString] mutableCopy];
        [URLStringWithParameters appendFormat:(mutableRequest.URL.query) ? @"&%@" : @"?%@", queryString];
        mutableRequest.URL = [NSURL URLWithString:URLStringWithParameters];
        
    } else
    {
        if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"])
        {
            NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));
            [mutableRequest setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
        }
        
        [mutableRequest setHTTPBody:[queryString dataUsingEncoding:self.stringEncoding]];
    }
    
    return [mutableRequest copy];
}

@end
