/*
 * © Rakuten, Inc.
 * authors: "Rakuten Mobile SDK Team | SDTD" <prj-rmsdk@mail.rakuten.com>
 */
#import <FXForms/FXForms.h>
#import <RSDKAnalytics/RSDKAnalytics.h>

/*
 * This form allows editing individual RSDKAnalyticsRecord instances.
 *
 * Known problems:
 * - The NSArray and NSDictionary properties cannot be edited at this
 *   point. We need to implement custom editors to fix that.
 */
@interface RSDKAnalyticsRecordForm : NSObject<FXForm>

// {{configuration
@property (nonatomic) BOOL trackLocation;
@property (nonatomic) BOOL trackIDFA;

// }}

// {{environment
@property (nonatomic) uint64_t accountId;
@property (nonatomic) int64_t serviceId;
@property (nonatomic) int64_t affiliateId;
@property (nonatomic, copy) NSString *goalId;
@property (nonatomic, copy) NSString *campaignCode;
@property (nonatomic, copy) NSString *shopId;
//}}

// {{region
@property (nonatomic, copy) NSString *contentLocale;
@property (nonatomic, copy) NSString *currencyCode;
// }}

// {{search
@property (nonatomic, copy) NSString *searchSelectedLocale;
@property (nonatomic, copy) NSString *searchQuery;
@property (nonatomic) RSDKAnalyticsSearchMethod searchMethod;
@property (nonatomic, copy) NSString *excludeWordSearchQuery;
@property (nonatomic, copy) NSString *genre;
// }}

// {{navigation
@property (nonatomic, copy) NSString *pageName;
@property (nonatomic, copy) NSString *pageType;
@property (nonatomic, copy) NSString *referrer;
@property (nonatomic) NSTimeInterval navigationTime;
@property (nonatomic) int64_t checkpoints;
// }}

// {{ items
@property (nonatomic, copy)   NSString *genreForItems;
@property (nonatomic, strong) NSArray  *itemIdentifiers;
// }}

// {{order
@property (nonatomic, copy) NSString *orderId;
@property (nonatomic) uint64_t cartState;
@property (nonatomic) RSDKAnalyticsCheckoutStage checkoutStage;
// }}

// {{other
@property (nonatomic, strong) NSArray *componentId;
@property (nonatomic, strong) NSArray *componentTop;
@property (nonatomic, strong) NSArray *scrollDivId;
@property (nonatomic, strong) NSArray *scrollViewed;
@property (nonatomic, copy) NSString *eventType;
@property (nonatomic, copy) NSString *requestCode;
@property (nonatomic, strong) NSDictionary *customParameters;
// }}

- (RSDKAnalyticsRecord *)record;
@end
