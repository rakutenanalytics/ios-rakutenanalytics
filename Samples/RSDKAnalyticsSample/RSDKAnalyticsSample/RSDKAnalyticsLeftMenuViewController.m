/*
 * © Rakuten, Inc.
 * authors: "Rakuten Mobile SDK Team | SDTD" <prj-rmsdk@mail.rakuten.com>
 */
#import "RSDKAnalyticsLeftMenuViewController.h"
#import "RSDKAnalyticsViewController.h"
#import "RSDKAnalyticsRecordForm.h"
#import <FontAwesomeKit/FAKFontAwesome.h>
#import <SVProgressHUD/SVProgressHUD.h>

/////////////////////////////////////////////////////////////////
static const CGFloat RSDKAnalyticsLeftMenuViewControllerFontSize  = 24;
static const CGFloat RSDKAnalyticsLeftMenuViewControllerIconRelativeSize  = 1.1;
static const CGFloat RSDKAnalyticsLeftMenuViewControllerRowHeight = RSDKAnalyticsLeftMenuViewControllerFontSize * 2;


@implementation RSDKAnalyticsLeftMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    CGFloat tableHeight = self.menuLabels_.count * RSDKAnalyticsLeftMenuViewControllerRowHeight;
    UITableView *tableView = [UITableView.alloc initWithFrame:CGRectMake(16,
                                                                         (self.view.frame.size.height - tableHeight) * 0.5,
                                                                         self.view.frame.size.width - 64,
                                                                         tableHeight)
                                                        style:UITableViewStylePlain];
    tableView.delegate   = self;
    tableView.dataSource = self;

    tableView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    tableView.opaque           = NO;
    tableView.backgroundColor  = UIColor.clearColor;
    tableView.backgroundView   = nil;
    tableView.separatorStyle   = UITableViewCellSeparatorStyleNone;
    tableView.bounces          = NO;
    tableView.scrollsToTop     = NO;
    tableView.rowHeight        = RSDKAnalyticsLeftMenuViewControllerRowHeight;

    [self.view addSubview:tableView];
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UINavigationController *navigationController = (UINavigationController *) self.sideMenuViewController.contentViewController;
    RSDKAnalyticsViewController *formController = (RSDKAnalyticsViewController *)navigationController.topViewController;

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.row) {
        case 0: // Reset
            [formController resetForm];
            [self.sideMenuViewController hideMenuViewController];
            break;
        case 1: // Spool
            [formController spool];
            break;
        case 2: // Upload history
            [SVProgressHUD showErrorWithStatus:@"Not implemented yet!"];
            break;
        case 3: // Local database
            [SVProgressHUD showErrorWithStatus:@"Not implemented yet!"];
            break;
        case 4: // About
            {
                static UIImage *infoImage;
                static dispatch_once_t once;
                dispatch_once(&once, ^
                {
                    FAKFontAwesome *infoIcon = [FAKFontAwesome infoCircleIconWithSize:62];
                    [infoIcon setAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor}];
                    infoImage = [infoIcon imageWithSize:CGSizeMake(56, 56)];
                });

                [SVProgressHUD showImage:infoImage
                                  status:[NSString stringWithFormat:@"RSDKAnalytics v%@", RSDKAnalyticsVersion]];
            }
            break;
        case 5: // Settings
            [SVProgressHUD showErrorWithStatus:@"Not implemented yet!"];
            break;
        default:
            break;
    }
}

#pragma mark UITableView Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return self.menuLabels_.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"menuCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [UITableViewCell.alloc initWithStyle:UITableViewCellStyleDefault
                                    reuseIdentifier:cellIdentifier];

        cell.selectedBackgroundView         = UIView.new;
        cell.backgroundColor                = UIColor.clearColor;
        cell.textLabel.textColor            = UIColor.whiteColor;
        cell.textLabel.highlightedTextColor = UIColor.lightGrayColor;
    }

    cell.textLabel.attributedText = self.menuLabels_[indexPath.row];

    return cell;
}

#pragma mark - Private methods

- (NSArray *)menuLabels_
{
    static NSArray *labels;
    static dispatch_once_t once;
    dispatch_once(&once, ^
    {
        const CGFloat textFontSize = RSDKAnalyticsLeftMenuViewControllerFontSize;
        UIFont *textFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:textFontSize];

        const CGFloat iconFontSize = textFont.lineHeight * RSDKAnalyticsLeftMenuViewControllerIconRelativeSize;
        const CGFloat baselineOffset = .5 * (textFontSize - iconFontSize);
        UIFont *iconFont = [FAKFontAwesome iconFontWithSize:iconFontSize];


        NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
        paragraphStyle.minimumLineHeight = iconFont.lineHeight - baselineOffset;

        NSDictionary *textAttributes = @{NSFontAttributeName: textFont,
                                         NSParagraphStyleAttributeName: paragraphStyle};

        NSDictionary *iconAttributes = @{NSFontAttributeName: iconFont,
                                         NSParagraphStyleAttributeName: paragraphStyle,
                                         NSBaselineOffsetAttributeName: @(baselineOffset)};

        labels = ({
            NSMutableArray *builder = NSMutableArray.new;
            for (NSString *labelString in @[@"\uf0e2 Reset",
                                            @"\uf093 Spool",
                                            @"\uf017 Upload history",
                                            @"\uf0ce Local database",
                                            @"\uf05a About",
                                            @"\uf013 Settings"
                                            ])
            {
                NSMutableAttributedString *attributed = [NSMutableAttributedString.alloc initWithString:labelString];
                [attributed setAttributes:iconAttributes range:NSMakeRange(0, 1)];
                [attributed setAttributes:textAttributes range:NSMakeRange(1, labelString.length - 1)];
                [builder addObject:attributed];
            }
            builder.copy;
        });
    });

    return labels;
}

@end

