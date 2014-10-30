//
//  RNetworkCertificateAuthenticator.m
//  RSDKSupport
//
//  Created by Zachary Radke on 1/8/14.
//  Copyright (c) 2014 Rakuten Inc. All rights reserved.
//

#import "RLoggingHelper.h"
#import "RNetworkCertificateAuthenticator.h"

@interface RNetworkCertificateAuthenticator ()
@property (strong, nonatomic, readwrite) NSArray *pinnedPublicKeys;
@end

@implementation RNetworkCertificateAuthenticator

#pragma mark - Default Certificates

+ (NSArray *)defaultPinnedCertificates
{
    static NSArray *_defaultPinnedCertificates;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleForClass:self];
        
        // By default we only look for certificates with .cer, .crt. and .der extensions
        NSArray *validCertificateExtensions = @[@"cer", @"crt", @"der"];
        
        NSMutableArray *paths = [NSMutableArray array];
        for (NSString *extension in validCertificateExtensions)
        {
            [paths addObjectsFromArray:[bundle pathsForResourcesOfType:extension inDirectory:nil]];
        }
        
        NSMutableArray *certificates = [NSMutableArray array];
        for (NSString *path in paths)
        {
            NSData *certificate = [NSData dataWithContentsOfFile:path];
            [certificates addObject:certificate];
        }
        
        _defaultPinnedCertificates = [NSArray arrayWithArray:certificates];
    });
    
    return _defaultPinnedCertificates;
}


#pragma mark - Creating instances

+ (instancetype)certificateAuthenticatorWithPolicy:(RCertificateAuthenticatorPolicy)authenticatorPolicy
{
    RNetworkCertificateAuthenticator *authenticator = [self new];
    authenticator.authenticatorPolicy = authenticatorPolicy;
    authenticator.pinnedCertificates = [self defaultPinnedCertificates];
    return authenticator;
}

- (instancetype)init
{
    if (!(self = [super init])) { return nil; }
    
    _allowAnyCertificate = NO;
    _validateEntireCertificateChain = NO;
    
    return self;
}


#pragma mark - Custom setter

- (void)setPinnedCertificates:(NSArray *)pinnedCertificates
{
    if (_pinnedCertificates == pinnedCertificates || [_pinnedCertificates isEqualToArray:pinnedCertificates]) { return; }
    
    [self willChangeValueForKey:NSStringFromSelector(@selector(pinnedCertificates))];
    _pinnedCertificates = pinnedCertificates;
    [self didChangeValueForKey:NSStringFromSelector(@selector(pinnedCertificates))];
    
    if (pinnedCertificates)
    {
        NSMutableArray *publicKeys = [NSMutableArray array];
        for (NSData *certificate in pinnedCertificates)
        {
            id publicKey = [self _publicKeyForCertificateData:certificate];
            if (publicKey) { [publicKeys addObject:publicKey]; }
        }
        
        self.pinnedPublicKeys = [NSArray arrayWithArray:publicKeys];
    } else
    {
        self.pinnedPublicKeys = nil;
    }
}


#pragma mark - Validating server trust

- (BOOL)validateServerTrust:(SecTrustRef)serverTrust
{
    // If the user doesn't wish to validate certificates, then we won't!
    if (self.authenticatorPolicy == RCertificateAuthenticatorPolicyNone && self.allowAnyCertificate)
    {
        return YES;
    }
    
    // Check if the server trust is valid at all
    if (![self _isValidServerTrust:serverTrust]) { return NO; }
    
    BOOL shouldTrustServer = NO;
    
    NSArray *certificateChain = [self _certificateChainForServerTrust:serverTrust];
    switch (self.authenticatorPolicy)
    {
        case RCertificateAuthenticatorPolicyNone:
            shouldTrustServer = YES;
            break;
        case RCertificateAuthenticatorPolicyPinCertificates:
        {
            if (!self.validateEntireCertificateChain)
            {
                shouldTrustServer = [self.pinnedCertificates containsObject:[certificateChain firstObject]];
            } else
            {
                NSUInteger trustedCertificateCount = 0;
                for (NSData *certificate in certificateChain)
                {
                    if ([self.pinnedCertificates containsObject:certificate])
                    {
                        trustedCertificateCount++;
                    }
                }
                
                shouldTrustServer = trustedCertificateCount > 0 && trustedCertificateCount == [certificateChain count];
            }
            break;
        }
        case RCertificateAuthenticatorPolicyPinPublicKeys:
        {
            NSArray *publicKeys = [self _publicKeysForServerTrust:serverTrust];
            if (publicKeys.count && !self.validateEntireCertificateChain)
            {
                publicKeys = [publicKeys subarrayWithRange:NSMakeRange(0, 1)];
            }
            
            NSUInteger trustedPublicKeyCount = 0;
            for (id publicKey in publicKeys)
            {
                for (id trustedPublicKey in self.pinnedPublicKeys)
                {
                    if ([trustedPublicKey isEqual:publicKey])
                    {
                        trustedPublicKeyCount++;
                        break; // Break out of this for loop, but continue with the outer one
                    }
                }
            }
            
            shouldTrustServer = trustedPublicKeyCount > 0 && trustedPublicKeyCount == [publicKeys count];
            
            break;
        }
        default:
            break;
    }
    
    return shouldTrustServer;
}


#pragma mark - Private utilities

- (BOOL)_isValidServerTrust:(SecTrustRef)serverTrust
{
    SecTrustResultType evaluationResult = 0;
    OSStatus status = SecTrustEvaluate(serverTrust, &evaluationResult);
    if (status != errSecSuccess) { RDebugLog(@"SecTrustEvaluate error: %d", (int)status); }
    
    return evaluationResult == kSecTrustResultUnspecified || evaluationResult == kSecTrustResultProceed;
}

- (NSArray *)_certificateChainForServerTrust:(SecTrustRef)serverTrust
{
    NSMutableArray *certificateChain = [NSMutableArray array];
    
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    for (NSInteger i = 0; i < certificateCount; i++)
    {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        if (!certificate) { return nil; }
        
        [certificateChain addObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)];
    }
    
    return [NSArray arrayWithArray:certificateChain];
}

- (NSArray *)_publicKeysForServerTrust:(SecTrustRef)serverTrust
{
    NSMutableArray *publicKeys = [NSMutableArray array];
    
    CFIndex publicKeyCount = SecTrustGetCertificateCount(serverTrust);
    for (NSUInteger i = 0; i < publicKeyCount; i++)
    {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        if (!certificate) { return nil; }
        
        id publicKey = [self _publicKeyForCertificate:certificate];
        
        if (publicKey)
        {
            [publicKeys addObject:publicKey];
        } else
        {
            return nil;
        }
    }
    
    return [NSArray arrayWithArray:publicKeys];
}

- (id)_publicKeyForCertificateData:(NSData *)certificateData
{
    SecCertificateRef certificate = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)certificateData);
    if (!certificate)
    {
        RDebugLog(@"SecCertificateCreateWithData error.");
        return nil;
    }
    
    id publicKey = [self _publicKeyForCertificate:certificate];
    CFRelease(certificate);
    
    return publicKey;
}

- (id)_publicKeyForCertificate:(SecCertificateRef)certificate
{
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    OSStatus status = SecTrustCreateWithCertificates(certificate, policy, &trust);
    if (status != errSecSuccess) { RDebugLog(@"SecTrustCreateWithCertificates error: %d", (int)status); }
    
    // The certificate must be evaluated before the public key can be extracted
    SecTrustResultType evaluationResult = 0;
    status = SecTrustEvaluate(trust, &evaluationResult);
    if (status != errSecSuccess) { RDebugLog(@"SecTrustEvaluate error: %d", (int)status); }
    
    SecKeyRef publicKey = SecTrustCopyPublicKey(trust);
    
    CFRelease(trust);
    CFRelease(policy);
    
    // The object returned isn't exactly NSData... but it should respond to -isEqual:
    return (__bridge id)publicKey;
}

@end
