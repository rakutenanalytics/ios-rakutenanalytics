/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import "_RSDKAnalyticsPrivateEvents.h"

/*
 * Card Scanner events - see https://confluence.rakuten-it.com/confluence/display/ESD/Usage+Tracking+for+Card+Scanner
 */
NSString *const _RSDKAnalyticsPrivateEventCardScannerVisit                   = @"_rem_cardscanner_visit";
NSString *const _RSDKAnalyticsPrivateEventCardScannerScanStarted             = @"_rem_cardscanner_scanui_scan";
NSString *const _RSDKAnalyticsPrivateEventCardScannerScanCanceled            = @"_rem_cardscanner_scanui_cancel";
NSString *const _RSDKAnalyticsPrivateEventCardScannerManual                  = @"_rem_cardscanner_scanui_manual";
NSString *const _RSDKAnalyticsPrivateEventCardScannerNumberScanned           = @"_rem_cardscanner_confirmui_ccnumber_scansuccess";
NSString *const _RSDKAnalyticsPrivateEventCardScannerNumberScanFailed        = @"_rem_cardscanner_confirmui_ccnumber_scanfailed";
NSString *const _RSDKAnalyticsPrivateEventCardScannerNumberModified          = @"_rem_cardscanner_confirmui_ccnumber_scanincorrect";
NSString *const _RSDKAnalyticsPrivateEventCardScannerCardTypeIdentified      = @"_rem_cardscanner_confirmui_cctype_identificationsuccess";
NSString *const _RSDKAnalyticsPrivateEventCardScannerCardTypeIdentifyFailed  = @"_rem_cardscanner_confirmui_cctype_identificationfailed";
NSString *const _RSDKAnalyticsPrivateEventCardScannerCardTypeModified        = @"_rem_cardscanner_confirmui_cctype_identificationincorrect";
NSString *const _RSDKAnalyticsPrivateEventCardScannerExpiryScanned           = @"_rem_cardscanner_confirmui_ccexpiry_scansuccess";
NSString *const _RSDKAnalyticsPrivateEventCardScannerExpiryScanFailed        = @"_rem_cardscanner_confirmui_ccexpiry_scanfailed";
NSString *const _RSDKAnalyticsPrivateEventCardScannerExpiryModified          = @"_rem_cardscanner_confirmui_ccexpiry_scanincorrect";
