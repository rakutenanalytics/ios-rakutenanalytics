#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import <RSDKAnalytics/RSDKAnalytics.h>

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
}


@end
