#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import <RAnalytics/RAnalytics.h>

@interface TodayViewController () <NCWidgetProviding>

@end

@implementation TodayViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    completionHandler(NCUpdateResultNewData);
}

- (IBAction)track:(id)sender {
    [[RAnalyticsRATTracker.sharedInstance eventWithEventType:@"widget_event" parameters:nil] track];
}


@end
