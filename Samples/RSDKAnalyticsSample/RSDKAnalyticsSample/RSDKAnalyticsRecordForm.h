#import <FXForms/FXForms.h>
#import <RAnalytics/RAnalytics.h>

/*
 * This form allows editing individual RSDKAnalyticsRecord instances.
 *
 * Known problems:
 * - The NSArray and NSDictionary properties cannot be edited at this
 *   point. We need to implement custom editors to fix that.
 */
@interface RSDKAnalyticsRecordForm : NSObject<FXForm>

@property (nonatomic) BOOL trackLocation;
@property (nonatomic) BOOL trackIDFA;
@property (nonatomic) BOOL useStaging;
@property (nonatomic) uint64_t accountId;
@property (nonatomic) int64_t serviceId;

@end
