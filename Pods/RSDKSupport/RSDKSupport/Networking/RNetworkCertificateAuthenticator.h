//
//  RNetworkCertificateAuthenticator.h
//  RSDKSupport
//
//  Created by Zachary Radke on 1/8/14.
//  Copyright (c) 2014 Rakuten Inc. All rights reserved.
//

@import Foundation;

/**
 * Authentication policy enumeration used by @ref RNetworkCertificateAuthenticator to determine how critically to examine server certificate credentials.
 *
 * @enum RCertificateAuthenticatorPolicy
 * @ingroup SupportConstants
 */
typedef NS_ENUM(NSInteger, RCertificateAuthenticatorPolicy) {
    /**
     * Only checks the validity of the server certificate.
     */
    RCertificateAuthenticatorPolicyNone = 0,
    /**
     * Checks server certificate against pinned certificates.
     */
    RCertificateAuthenticatorPolicyPinCertificates,
    /**
     * Checks server certificate public keys against pinned cerficiate public keys.
     */
    RCertificateAuthenticatorPolicyPinPublicKeys
};

/**
 * Class used to verify server certificates in authentication challenge delegate methods. Once an instance has been created and configured, it can evaluate a server trust using the #validateServerTrust: method. Primarily, this class provides a simplified way to use SSL pinning of certificates or public keys, which can help protect against man-in-the-middle attacks. Only server trusts with matching pinned certificates/public keys will be considered valid. Please note that the Security framework requires certificates to be in the `.der` format, so ensure that any pinned certificates are formatted correctly prior to setting them on a certificate authenticator.
 *
 * @class RNetworkCertificateAuthenticator RNetworkCertificateAuthenticator.h <RSDKSupport/RNetworkCertificateAuthenticator.h>
 */
@interface RNetworkCertificateAuthenticator : NSObject

/**
 *  A singleton array of certificates included in the main bundle, which can be used to validate a server trust. This will load certificates with the `.cer`, `.crt` and `.der` extensions in the bundle that contains this class.
 *
 *  @return An array of certificates as `NSData` objects.
 *
 *  @note Only certificates in the `.der` format will be considered valid by the Security framework.
 */
+ (NSArray *)defaultPinnedCertificates;

/**
 * Generate certificate authenticators with a given authentication policy. Instances returned by this method will use the #defaultPinnedCertificates as their #pinnedCertificates property.
 *
 * @param authenticatorPolicy The authentication policy to use.
 *
 * @return A new instance of the receiver.
 */
+ (instancetype)certificateAuthenticatorWithPolicy:(RCertificateAuthenticatorPolicy)authenticatorPolicy;

/**
 *  The authentication policy of this instance.
 */
@property (assign, nonatomic) RCertificateAuthenticatorPolicy authenticatorPolicy;

/**
 *  An array of certificates, represented as `NSData` objects, which are used to validate servers trust.
 *
 *  @note These certificates must be in the `.der` format.
 */
@property (strong, nonatomic) NSArray *pinnedCertificates;

/**
 *  A read-only array of pinned public keys, which can be used to validate servers trust. These keys are automatically generated from #pinnedCertificates.
 */
@property (strong, nonatomic, readonly) NSArray *pinnedPublicKeys;

/**
 *  A flag indicating whether only the last certificate should be validated, or if the entire certificate chain should be validated. This applies to both certificate and public key pinned authentication policies. By default this is `NO`.
 */
@property (assign, nonatomic) BOOL validateEntireCertificateChain;

/**
 *  A flag indicating whether all certificates should be allowed or not. If the authentication policy is set to RCertificateAuthenticatorPolicyNone and this flag is `YES`, then any validation of server trusts will result positively, otherwise, this parameter is ignored. By default this is `NO`.
 */
@property (assign, nonatomic) BOOL allowAnyCertificate;

/**
 *  Validates a server's certificate chain based on the current configuration. This method should be called from an authentication challenge delegate to help determine the authenticity of a server's trust.
 *
 *  @param serverTrust The server trust to validate. Typically this is aquired through an `NSURLProtectionSpace` instance.
 *
 *  @return A flag indicating if the server trust is valid or not.
 *
 *  @note This method should **NOT** be called on the main thread. During certificate evaluation, certificates may need to be downloaded over the network, which will block whatever thead is currently running. Instead use GCD or `NSOperationQueue` to run this method in the background.
 */
- (BOOL)validateServerTrust:(SecTrustRef)serverTrust;

@end
