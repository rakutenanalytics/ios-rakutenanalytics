//
//  RNetworkResponseSerializer.m
//  RSDKSupport
//
//  Created by Zachary Radke on 11/19/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//
//  Copied shamelessly from https://github.com/AFNetworking/AFNetworking

#import "RNetworkResponseSerializer.h"

NSString *const RNetworkResponseErrorDomain = @"jp.co.rakuten.sdk.networkResponse.errorDomain";

@implementation RNetworkResponseSerializer

+ (instancetype)serializer
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    
    return self;
}

- (BOOL)validateResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        // Validate the status code
        if (self.acceptableStatusCodes && ![self.acceptableStatusCodes containsIndex:response.statusCode])
        {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Invalid status code: %@ (%ld)", [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode], (long)response.statusCode],
                                       NSURLErrorFailingURLErrorKey: response.URL ?: [NSNull null]};
            if (error != NULL)
            {
                *error = [NSError errorWithDomain:RNetworkResponseErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
            }
            
            return NO;
        }
        
        // Validate the content type
        if (self.acceptableContentTypes && ![self.acceptableContentTypes containsObject:response.MIMEType])
        {
            if (data.length > 0)
            {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Invalid content type: %@", response.MIMEType],
                                           NSURLErrorFailingURLErrorKey: response.URL ?: [NSNull null]};
                
                if (error != NULL)
                {
                    *error = [NSError errorWithDomain:RNetworkResponseErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo];
                }
                
                return NO;
            }
        }
    }
    
    return YES;
}

- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error])
    {
        if ([(NSError *)(*error) code] == NSURLErrorCannotDecodeContentData)
        {
            return nil;
        }
    }
    
    return data;
}

@end


@implementation RJSONResponseSerializer

+ (instancetype)serializer
{
    return [self serializerWithJSONReadingOptions:0];
}

+ (instancetype)serializerWithJSONReadingOptions:(NSJSONReadingOptions)options
{
    RJSONResponseSerializer *serializer = [self new];
    serializer.readingOptions = options;
    
    return serializer;
}

- (instancetype)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    self.stringEncoding = NSUTF8StringEncoding;
    self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];
    
    return self;
}

- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if (![super responseObjectForResponse:response data:data error:error]){ return nil; }
    
    NSStringEncoding encoding = self.stringEncoding;
    if (response.textEncodingName)
    {
        CFStringEncoding baseEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)response.textEncodingName);
        
        if (baseEncoding != kCFStringEncodingInvalidId)
        {
            encoding = CFStringConvertEncodingToNSStringEncoding(baseEncoding);
        }
    }
    
    NSString *responseString = [[NSString alloc] initWithData:data encoding:encoding];
    if (responseString && ![responseString isEqualToString:@" "])
    {
        data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        
        if (data)
        {
            return (data.length > 0) ? [NSJSONSerialization JSONObjectWithData:data options:self.readingOptions error:error] : nil;
        } else
        {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to convert string to UTF8 data: %@", responseString]};
            
            if (error != NULL)
            {
                *error = [NSError errorWithDomain:RNetworkResponseErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo];
            }
        }
    }
    
    return nil;
}

@end
