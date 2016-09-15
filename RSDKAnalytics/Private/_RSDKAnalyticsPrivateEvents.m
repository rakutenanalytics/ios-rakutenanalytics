/*
 * © Rakuten, Inc.
 * authors: "Rakuten Ecosystem Mobile" <ecosystem-mobile@mail.rakuten.com>
 */
#import "_RSDKAnalyticsPrivateEvents.h"

/*
 * Card Info events - see https://confluence.rakuten-it.com/confluence/display/ESD/Usage+Tracking+for+Card+Info
 */
NSString *const _RSDKAnalyticsPrivateEventCardInfoScanStarted             = @"_rem_cardinfo_scanui_scan";
NSString *const _RSDKAnalyticsPrivateEventCardInfoScanCanceled            = @"_rem_cardinfo_scanui_cancel";
NSString *const _RSDKAnalyticsPrivateEventCardInfoManual                  = @"_rem_cardinfo_scanui_manual";
NSString *const _RSDKAnalyticsPrivateEventCardInfoNumberScanned           = @"_rem_cardinfo_confirmui_ccnumber_scansuccess";
NSString *const _RSDKAnalyticsPrivateEventCardInfoNumberScanFailed        = @"_rem_cardinfo_confirmui_ccnumber_scanfailed";
NSString *const _RSDKAnalyticsPrivateEventCardInfoNumberModified          = @"_rem_cardinfo_confirmui_ccnumber_scanincorrect";
NSString *const _RSDKAnalyticsPrivateEventCardInfoCardTypeIdentified      = @"_rem_cardinfo_confirmui_cctype_identificationsuccess";
NSString *const _RSDKAnalyticsPrivateEventCardInfoCardTypeIdentifyFailed  = @"_rem_cardinfo_confirmui_cctype_identificationfailed";
NSString *const _RSDKAnalyticsPrivateEventCardInfoCardTypeModified        = @"_rem_cardinfo_confirmui_cctype_identificationincorrect";
NSString *const _RSDKAnalyticsPrivateEventCardInfoExpiryScanned           = @"_rem_cardinfo_confirmui_ccexpiry_scansuccess";
NSString *const _RSDKAnalyticsPrivateEventCardInfoExpiryScanFailed        = @"_rem_cardinfo_confirmui_ccexpiry_scanfailed";
NSString *const _RSDKAnalyticsPrivateEventCardInfoExpiryModified          = @"_rem_cardinfo_confirmui_ccexpiry_scanincorrect";

/*
 * Discover events - see https://confluence.rakuten-it.com/confluence/display/ESD/Usage+Tracking+for+Discover
 */
NSString *const _RSDKAnalyticsPrivateEventDiscoverPageVisit               = @"_rem_discover_discoverpage_visit";
NSString *const _RSDKAnalyticsPrivateEventDiscoverPageTap                 = @"_rem_discover_discoverpage_tap";
NSString *const _RSDKAnalyticsPrivateEventDiscoverPageRedirect            = @"_rem_discover_discoverpage_redirect";
NSString *const _RSDKAnalyticsPrivateEventDiscoverPreviewVisit            = @"_rem_discover_discoverpreview_visit";
NSString *const _RSDKAnalyticsPrivateEventDiscoverPreviewTap              = @"_rem_discover_discoverpreview_tap";
NSString *const _RSDKAnalyticsPrivateEventDiscoverPreviewRedirect         = @"_rem_discover_discoverpreview_redirect";
NSString *const _RSDKAnalyticsPrivateEventDiscoverPreviewShowMore         = @"_rem_discover_discoverpreview_showmore";
