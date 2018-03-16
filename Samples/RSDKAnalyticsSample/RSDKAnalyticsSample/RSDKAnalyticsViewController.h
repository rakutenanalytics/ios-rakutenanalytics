#import <FXForms/FXForms.h>

/////////////////////////////////////////////////////////////////

@interface RSDKAnalyticsViewController : FXFormViewController

/*
 * Reset the form.
 */
- (IBAction)resetForm;

/*
 * Build a new RSDKAnalyticsRecord from the values currently set
 * in the form, then spool it.
 */
- (IBAction)spool;
@end

