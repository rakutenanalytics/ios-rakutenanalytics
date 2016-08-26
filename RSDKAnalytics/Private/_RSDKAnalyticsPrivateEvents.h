/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

/*
 * Event triggered when app launches the Card Scanner module
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardScannerVisit;

/*
 * Event triggered when the user starts the camera scan screen
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardScannerScanStarted;

/*
 * Event triggered when the user cancels the camera scan screen
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardScannerScanCanceled;

/*
 * Event triggered when the user opts to enter their card details manually
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardScannerManual;

/*
 * Event triggered when the Card Scanner SDK has scanned the card number
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardScannerNumberScanned;

/*
 * Event triggered when the Card Scanner SDK failed to scan the card number
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardScannerNumberScanFailed;

/*
 * Event triggered when the user modified the scanned card number in the Card Scanner UI
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardScannerNumberModified;

/*
 * Event triggered when the Card Scanner SDK has identified the card type
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardScannerCardTypeIdentified;

/*
 * Event triggered when the Card Scanner SDK has failed to identify the card type
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardScannerCardTypeIdentifyFailed;

/*
 * Event triggered when the user modified the identified card type in the Card Scanner UI
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardScannerCardTypeModified;

/*
 * Event triggered when the Card Scanner SDK has scanned the card expiry
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardScannerExpiryScanned;

/*
 * Event triggered when the Card Scanner SDK failed to scan the card expiry
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardScannerExpiryScanFailed;

/*
 * Event triggered when the user modified the scanned card expiry in the Card Scanner UI
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardScannerExpiryModified;
