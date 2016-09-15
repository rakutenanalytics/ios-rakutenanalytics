/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import <RSDKAnalytics/RSDKAnalyticsDefines.h>

/*
 * Event triggered when the user starts the camera scan screen
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardInfoScanStarted;

/*
 * Event triggered when the user cancels the camera scan screen
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardInfoScanCanceled;

/*
 * Event triggered when the user opts to enter their card details manually
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardInfoManual;

/*
 * Event triggered when the external scan SDK has scanned the card number
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardInfoNumberScanned;

/*
 * Event triggered when the external scan SDK failed to scan the card number
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardInfoNumberScanFailed;

/*
 * Event triggered when the user modified the scanned card number in the Card Info UI
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardInfoNumberModified;

/*
 * Event triggered when the external scan SDK has identified the card type
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardInfoCardTypeIdentified;

/*
 * Event triggered when the external scan SDK has failed to identify the card type
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardInfoCardTypeIdentifyFailed;

/*
 * Event triggered when the user modified the identified card type in the Card Info UI
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardInfoCardTypeModified;

/*
 * Event triggered when the external scan SDK has scanned the card expiry
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardInfoExpiryScanned;

/*
 * Event triggered when the external scan SDK failed to scan the card expiry
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardInfoExpiryScanFailed;

/*
 * Event triggered when the user modified the scanned card expiry in the Card Info UI
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventCardInfoExpiryModified;

/**
 * Discover events
 */
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventDiscoverPageVisit;
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventDiscoverPageTap;
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventDiscoverPageRedirect;
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventDiscoverPreviewVisit;
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventDiscoverPreviewTap;
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventDiscoverPreviewRedirect;
RSDKA_EXPORT NSString *const _RSDKAnalyticsPrivateEventDiscoverPreviewShowMore;
