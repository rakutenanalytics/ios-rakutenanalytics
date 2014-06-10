Purpose
--------------

FXForms is an Objective-C library for easily creating table-based forms on iOS. It is ideal for settings pages or data-entry tasks.

Unlike other solutions, FXForms works directly with strongly-typed data models that you supply (instead of dictionaries or complicated dataSource protocols), and infers as much information as possible from your models using introspection, to avoid the need for tedious duplication of type information.

![Screenshot of BasicExample](https://raw.github.com/nicklockwood/FXForms/1.0.2/Examples/BasicExample/Screenshot.png)

Supported iOS & SDK Versions
-----------------------------

* Supported build target - iOS 7.1 (Xcode 5.1)
* Earliest supported deployment target - iOS 5.0
* Earliest compatible deployment target - iOS 5.0

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this iOS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


ARC Compatibility
------------------

FXForms requires ARC. If you wish to use FXForms in a non-ARC project, just add the `-fobjc-arc` compiler flag to the `FXForms.m` class. To do this, go to the Build Phases tab in your target settings, open the Compile Sources group, double-click `FXForms.m` in the list and type `-fobjc-arc` into the popover.

If you wish to convert your whole project to ARC, comment out the #error line in `FXForms.m`, then run the Edit > Refactor > Convert to Objective-C ARC... tool in Xcode and make sure all files that you wish to use ARC for (including `FXForms.m`) are checked.


Creating a form
------------------

To create a form object, just make any new `NSObject` subclass that conforms to the `FXForm` protocol, like this:

```objc
@interface MyForm : NSObject <FXForm>

@end
```

The `FXForm` protocol has no compulsory methods or properties. The FXForms library will inspect your object and identify all public and private properties and use them to generate the form. For example, suppose you wanted to have a form containing an "Email" and "Password" field,  and a "Remember Me" switch; you would define it like this:

```objc
@interface MyForm : NSObject <FXForm>

@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, assign) BOOL rememberMe;

@end
```

That's literally all you have to do. FXForms is *really* smart; much more so than you might expect:

* Fields will appear in the same order you declare them in your class
* Fields will automatically be assigned suitable control types, for example, the rememberMe field will be displayed as a `UISwitch`, the email field will automatically have a keyboard of type `UIKeyboardTypeEmailAddress` and the password field will automatically have `secureTextEntry` enabled. 
* Field titles are based on the key name, but camelCase is automatically converted to a Title Case, with intelligent handling of ACRONYMS, etc.
* Modifying values in the form will automatically assign those values back to your model object. You can use custom setter methods and/or KVO to intercept the changes if you need to perform additional logic.
* If your form contains subforms (properties that conform to the `FXForm` protocol), or view controllers (e.g for terms and conditions pages), they will automatically be instantiated if they are nil - no need to set default values.

These default behaviors are all inferred by inspecting the property type and name using Objective-C's runtime API, but they can also all be overridden if you wish - that's covered later under Tweaking form behavior


Displaying a form (basic)
----------------------------

To display your form in a view controller, you have two options: `FXForms` provides a `UIViewController` subclass called `FXFormViewController` that is designed to make getting started as simple as possible. To set up `FXFormViewController`, just create it as normal and set your form as follows:

```objc
FXFormViewController *controller = [[FXFormViewController alloc] init];
controller.formController.form = [[MyForm alloc] init];
```

You can then display the form controller just as you would do any ordinary view controller. `FXFormViewController` contains a `UITableView`, which it will create automatically as needed. If you prefer however, you can assign your own `UITableView` to the `tableView` property and use that instead. You can even initialize the `FXFormViewController` with a nib file that creates the tableView.

`FXFormViewController` is designed to be subclassed, just like a regular `UIViewController` or `UITableViewController`. In most cases, you'll want to subclass `FXFormViewController` so you can add your form setup logic and action handlers. 

It is a good idea to place the `FXFormViewController` (or subclass) inside a `UINavigationController`. This is not mandatory, but if the form contains subforms, these will be pushed onto its navigationController, and if that does not exist, the forms will not be displayed.

Like `UITableViewController`, `FXFormViewController` will normally assign the tableView as the main view of the controller. Unlike `UITableViewController`, it doesn't *have* to be - you can make your tableView a subview of your main view if you prefer.

Like `UITableViewController`, `FXFormViewController` implements the `UITableViewDelegate` protocol, so if you subclass it, you can override the `UITableViewDelegate` and `UIScrollViewDelegate` methods to implement custom behaviors. `FXFormViewController` is not actually the direct delegate of the tableView however, it is the delegate of its formController, which is an instance of `FXFormController`. The formController acts as the tableView's delegate and datasource, and proxies the `UITableViewDelegate` methods back to the `FXFormViewController` via the `FXFormControllerDelegate` protocol.

Unlike `UITableViewController`, `FXFormViewController` does not implement `UITableViewDataSource` protocol. This is handled entirely by the `FXFormController`, and it is not recommended that you try to override or intercept any of the datasource methods.


Displaying a form (advanced)
----------------------------

The `FXFormViewController` is pretty flexible, but sometimes it's inconvenient to be forced to use a particular base controller class. For example, you may wish to use a common base class for all your view controllers, or display a form inside a view that does not have an associated controller.

In the former case, you could add an `FXFormViewController` as a child controller, but in the latter case that wouldn't work. To use FXForms without using `FXFormViewController`, you can use the `FXFormController` directly. To display a form using `FXFormController`, you just need to set the form and tableView properties, and it will do the rest. You can optionally bind the `FXFormController`'s delegate property to be notified of `UITableView` events.

When using a custom form view controller in this way, some interactions are still handled for you (e.g. adjusting the table view content inset when the keyboard is presented), but you will need to add other view logic yourself, such as reloading the table when the `UIViewController` appears on screen.

Here is example code for a custom form view controller:

```objc
@interface MyFormViewController : UIViewController <FXFormControllerDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) FXFormController *formController;

@end

@implementation MyFormViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //we'll assume that tableView has already been set via a nib or the -loadView method
    self.formController = [[FXFormController alloc] init];
    self.formController.tableView = self.tableView;
    self.formController.delegate = self;
    self.formController.form = [[MyForm alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //reload the table
    [self.tableView reloadData];
}

@end
```


Tweaking form behavior
------------------------

FXForm's greatest strength is that it eliminates work by guessing as much as possible. It can't guess everything however, and it sometimes guesses wrong. So how do you correct it?

You may find that you don't want all of your object properties to become form fields; you may have private properties that are used internally by your form model for example, or you may just wish to order the fields differently to how you've arranged your properties in the interface.

To override the list of form fields, implement the optional `-fields` method of your form:

```objc
- (NSArray *)fields
{
    return @[@"field1", @"field2", @"field3"];
}
```

The fields method should return an array of strings, dictionaries, or a mixture. In the example we have returned strings; these map to the names of properties of the form object. If you return an array of names like this, these fields will replace the automatically generated field list.

The `-fields` method will be called again every time the form is reassigned to the formController. That means that you can generate the fields dynamically, based on application logic. For example, you could show or hide certain fields based on other properties.

In addition to omitting and rearranging fields, you may wish to override their attributes. There are two ways to do this: One way is to add a method to the form object, such as `-(NSDictionary *)[name]Field;` where name is the property that the field relates to. This method returns a dictionary of properties that you wish to override (see Form field properties, below). For example, if we wanted to override the title of the email field, we could do it like this:

```objc
- (NSDictionary *)emailField
{
    return @{FXFormFieldTitle: @"Email Address"};
}
```

Alternatively, you can return a dictionary in the `-fields` array instead of a string. If you do this, you must include the `FXFormFieldKey` so that FXForms knows which field you are overriding:

```objc
- (NSArray *)fields
{
    return @[
             @{FXFormFieldKey: @"email", FXFormFieldTitle: @"Email Address"},
             …other fields…
            ];
}
```

These two approaches are equivalent.

Finally, you may wish to add additional, virtual form fields (e.g. buttons or labels) that don't correspond to any properties on your form class. You can do this by implementing the `-fields` method, but if you're happy with the default fields and just want to add some extra fields at the end, you can override the `-extraFields` method instead, which works the same way, but leaves in place the default fields inferred from the form class:

```objc
- (NSArray *)extraFields
{
    return @[
             @{FXFormFieldTitle: @"Extra Field"},
            ];
}
```


Grouping fields
---------------------

You may wish to group your form fields into sections in the form to make it ease to use. FXForms handles grouping in a very simple way - you just add an `FXFormFieldHeader` or `FXFormFieldFooter` attribute to any field and it will start/end the section at that point. The `FXFormFieldHeader/Footer` is a string that will be displayed as the header or footer text for the section. If you don't want any text, just supply an empty string.

In the following example, we have four fields, and we've split them into two groups, each with a header:

```objc
- (NSArray *)fields
{
    return @[
             @{FXFormFieldKey: @"field1", FXFormFieldHeader: @"Section 1"},
             @"field2",
             @{FXFormFieldKey: @"field3", FXFormFieldHeader: @"Section 2"},
             @"field4",
            ];
}
```

Alternatively, since we aren't overriding any other field properties, we could have done this more cleanly by using the following approach:

```objc
- (NSDictionary *)field1Field
{
    return @{FXFormFieldHeader: @"Section 1"};
}

- (NSDictionary *)field3Field
{
    return @{FXFormFieldHeader: @"Section 2"};
}
```


Form field properties
------------------------

The list of form field properties that you can set are as follows. Most of these have sensible defaults set automatically. Note that the string values of these constants are declared in the interface - you can assume that the string values of these constants will no change in future releases, and you can safely use these values in (for example) a plist used to configure the form.

```objc
static NSString *const FXFormFieldKey = @"key";
```
    
This is the name of the related property of the form object. If your field isn't backed by a real property, this might be the name of a getter method used to populate the field value. It's also possible to have completely virtual fields (such as buttons) that do not have a key at all.
    
```objc
static NSString *const FXFormFieldType = @"type";
```
    
This is the field type, which is used to decide how the field will be displayed in the table. The type is used to determine which type of cell to use to represent the field, but it may also be used to configure the cell (a single cell class may support multiple field types). The type is automatically inferred from the field property declaration, but can be overridden. Supported types are listed under Form field types below, however you can supply any string as the type and implement a custom form cell to display and/or edit it.

```objc
static NSString *const FXFormFieldClass = @"class";
```

This is the class of the field value. For primitive types, this will be the class used to box the value when accessed via KVC (e.g. `NSNumber` for numeric values, or `NSValue` for `struct` types). This is automatically determined for all properties of the form, so you rarely need to set it yourself. For form properties that you add yourself using the `-fields` or `-extraFields` methods, it is sometimes helpful to specify this explicitly. A good example would be if you are adding view controller or subform fields, where the class cannot usually be inferred automatically. The value provided can be either a `Class` object or a string representing the class name.


```objc
static NSString *const FXFormFieldCell = @"cell";
```

This is the class of the cell used to represent the field. By default this value is not specified on the field-level; instead, the `FXFormController` maintains a map of fields types to cell classes, which allows you to override the default cells used to display a given field type on a per-form level rather than having to do it per-field. If you *do* need to provide a special one-off cell type, you can use this property to do so. The value provided can be either a `Class` object or a string representing the class name.
    
```objc
static NSString *const FXFormFieldTitle = @"title";
```
    
This is the display title for the field. This is automatically generated from the key by converting from camelCase to Title Case, and then localised by running it through the `NSLocalizedString()` macro. That means that instead of overriding the title using this key, you can do so in your strings file instead if you prefer.

```objc
static NSString *const FXFormFieldPlaceholder = @"placeholder";
```

This is the placeholder value to display when the field value is nil or empty. This is typically a string, but doesn't have to be, for example it could be an NSDate for a date field, or a UIImage for an image field. When used with an options or multi-select field, the placeholder will appear as the first item in the options list, and can be used to reset the field to nil / no value.
    
```objc
static NSString *const FXFormFieldOptions = @"options";
```
    
For any field type, you can supply an array of supported values, which will override the standard field with a checklist of options to be selected instead. The options can be NSStrings, NSNumbers or any other object type. You can supply an `FXFormFieldValueTransformer` to control how the option values are displayed in the list. Alternatively, if you use a custom object for the values, you can implement the `-(NSString *)fieldDescription;` method to control how it is displayed. See Form field options below for more details.

```objc
static NSString *const FXFormFieldValueTransformer = @"valueTransformer";
```

Sometimes the value you wish to display for a field may not match the value you store. For example, you might want to display a date in a  particular format, or convert a locale code into its human-readable equivalent. The `FXFormFieldValueTransformer` property lets you specify either a conversion block or an `NSValueTransformer` to use for converting the field value to a string. If a value transformer is provided, it will be used instead of calling the `-fieldDescription` method of the field's value object. You can supply either an instance of `NSValueTransformer` or the name of an `NSValueTransformer` subclass. If the form field has an options array, the value transformer will also be used to control how the options are displayed in the list.

```objc
static NSString *const FXFormFieldAction = @"action";
```
    
This is an optional action to be performed when by the field. The value can be either a string representing the name of a selector, or a block, and will be executed when the field is activated. If the action is specified as a selector, the target is determined by cascading up the responder chain from the cell until an object is encountered that responds to it. That means that you could choose to implement this action method on the tableview, it's superview, the view controller, the app delegate, or even the window. If your form is presented as a subform of another form, you can also implement actions methods for subforms in the view controller for their parent form.

For non-interactive fields, the action will be called when the cell is selected; for fields such as switches or textfields, it will fire when the value is changed. When using a selector, the action method can accept either zero or one argument. The argument supplied will be the sender, which is typically a form field cell, (a `UITableViewCell` conforming to the `FXFormFieldCell` protocol), from which you can access the field model, and from that the form itself.

```objc
static NSString *const FXFormFieldHeader = @"header";
```
    
This property provides an optional section header string to display before the field. Supply an empty string to create a section partition without a title.
    
```objc
static NSString *const FXFormFieldFooter = @"footer";
```
    
This property provides an optional section footer string to display after the field. Supply an empty string to create a section partition without a footer.
    
```objc
static NSString *const FXFormFieldInline = @"inline";
```

Fields whose values is another FXForm, or which have a supplied options array, will normally be displayed in a new FXFormViewController, which is pushed onto the navigation stack when you tap the field. You may wish to display such fields inline within same tableView instead. You can do this by setting the `FXFormFieldInline` property to `@YES`.

```objc
static NSString *const FXFormFieldViewController = @"controller";
```

Some types of field may be displayed in another view controller, which will be pushed onto the navigation stack when the field is selected. By default this class is not specified on the field-level; instead, the `FXFormController` maintains a map of fields types to controller classes, which allows you to override the default controller used to display a given field type on a per-form level rather than having to do it per-field. If you *do* need to provide a special one-off controller type, the FXFormFieldViewController property lets you specify the controller to be used on a per-field basis. The controller specified must conform to the `FXFormFieldViewController` protocol. By default, such fields will be displayed using the `FXFormViewController` class.


Form field types
------------------------

```objc
static NSString *const FXFormFieldTypeDefault = @"default";
```
    
This is the default field type, used if no specific type can be determined.
    
```objc
static NSString *const FXFormFieldTypeLabel = @"label";
```
    
This type can be used if you want the field to be treated as non-interactive/read-only. Form values will be displayed by converting the value to a string using the `-fieldDescription` method. This maps to the standard `NSObject -description` method for all built-in types, but you can override it for your own custom value classes.
    
```objc
static NSString *const FXFormFieldTypeText = @"text";
```
    
By default, this field type will be represented by an ordinary `UITextField` with default autocorrection.
    
```objc
static NSString *const FXFormFieldTypeLongText = @"longtext";
```

This type represents multiline text. By default, this field type will be represented by an expanding `UITextView`.
    
```objc
static NSString *const FXFormFieldTypeURL = @"url";
```
    
Like `FXFormFieldTypeText`, but with a keyboard type of `UIKeyboardTypeURL`, and no autocorrection.
    
```objc
static NSString *const FXFormFieldTypeEmail = @"email";
```
    
Like `FXFormFieldTypeText`, but with a keyboard type of `UIKeyboardTypeEmailAddress`, and no autocorrection.
    
```objc
static NSString *const FXFormFieldTypePassword = @"password";
```
    
Like `FXFormFieldTypeText`, but with secure text entry enabled, and no autocorrection.
    
```objc
static NSString *const FXFormFieldTypeNumber = @"number";
```
    
Like `FXFormFieldTypeText`, but with a numeric keyboard, and input restricted to a valid number.

```objc
static NSString *const FXFormFieldTypeInteger = @"integer";
```
    
Like `FXFormFieldTypeNumber`, but restricted to integer input.

```objc
static NSString *const FXFormFieldTypeFloat = @"float";
```
    
Like `FXFormFieldTypeNumber`, but indicates value is primitive (not-nillable)
    
```objc
static NSString *const FXFormFieldTypeBoolean = @"boolean";
```
    
A boolean value, set using a `UISwitch` control.

```objc
static NSString *const FXFormFieldTypeOption = @"option";
```

Like `FXFormFieldTypeBoolean`, but this type is used for toggle options and by default is creates a checkmark control instead of a switch.
    
```objc
static NSString *const FXFormFieldTypeDate = @"date";
```

A date value, selected using a `UIDatePicker`.

```objc
static NSString *const FXFormFieldTypeTime = @"time";
```

A time value, selected using a `UIDatePicker`.

```objc
static NSString *const FXFormFieldTypeDateTime = @"datetime";
```

A date and time, selected using a `UIDatePicker`.

```objc
static NSString *const FXFormFieldTypeImage = @"image"
```

An image, selected using a `UIImagePickerController`.


Form field options
----------------------

When you provide an options array for a form field, the field input will be presented as a list of options to tick. How this list of options is converted to the form value depends on the type of field:

If the field type matches the values in the options array, selecting the option will set the selected value directly, but that may not be what you want. For example, if you have a list of strings, you may be more interested in the selected index than the value (which may have been localised and formatted for human consumption, not machine interpretation). If the field type is numeric, and the options values are not numeric, it will be assumed that the field value should be set to the *index* of the selected item, instead of the value.

If the field is a collection type (such as NSArray, NSSet, etc.), the form will allow the user to select multiple options instead of one. Collections are handled as followed, depending on the class of the property: If you use `NSArray`, `NSSet` and `NSOrderedSet`, the selected values will be stored directly in the collection; If you use an `NSIndexSet`, the indexes of the values will be stored; If you use `NSDictionary`, both the values *and* their indexes will be stored. For ordered collection types, the order of the selected values is guaranteed to match the order in the options array.

Multi-select fields can also be used with `NS_OPTIONS`-style bitfield enum values. Just use an integer or enum as your property type, and then specify a field type of `FXFormFieldTypeBitfield`. You can then either specify explicit bit values in your options by using `NSNumber` values, or let FXForms infer the bit value from the option index.

*NOTE:* the actual values defined in your enum are not available to FXForms at runtime, so the selected values will be purely determined by the index of value of the options in the `FXFormFieldOptions` value. If your enum values are non-sequential, or do not begin at zero, the indices won't match the options indexes. To define enum options with non-sequential values, you can specify explicit numeric option values and use `FXFormFieldValueTransformer` to display human readable labels, like this:

```objc
typedef NS_ENUM(NSInteger, Gender)
{
    GenderMale = 10,
    GenderFemale = 15,
    GenderOther = -1
};

- (NSDictionary *)genderField
{
    return @{FXFormFieldOptions: @[@(GenderMale), @(GenderFemale), @(GenderOther)],
             FXFormFieldValueTransformer: ^(id input) {
             return @{@(GenderMale): @"Male",
                      @(GenderFemale): @"Female",
                      @(GenderOther): @"Other"}[input];
    }};
}
```


Cell configuration
-------------------

If you want to tweak some properties of the field cells, without subclassing them, you can actually set any cell property by keyPath, just by adding extra values to your field dictionary. For example, this code would turn the textLabel for the email field red:

```objc
- (NSDictionary *)emailField
{
    return @{@"textLabel.color": [UIColor redColor]};
}
```

This code would disable auto-capitalisation for the name field:

```objc
- (NSDictionary *)nameField
{
    return @{@"textField.autocapitalizationType": @(UITextAutocapitalizationTypeNone)};
}
```
    
Cells are not recycled in the FXForm controller, so you don't need to worry about cleaning up any properties that you set in this way. Be careful of overusing "stringly typed" code such as this however, as errors can't be caught at compile time. For heavy customisation, it is better to create cell subclasses and override properties in the `-setField:` method.
    

Custom cells
----------------

FXForms provides default cell implementations for all supported fields. You may wish to provide additional cell classes for custom field types, or even replace all of the FXForm cells with custom versions for your application.

There are two levels of customisation possible for cells. The simplest option is to subclass one of the existing `FXFormCell` classes, which all inherit from `FXFormBaseCell`. These cell classes contain a lot of logic for handling the various different field types, but expose the views and controls used, for easy customisation.

If you already have a base cell class and don't want to base your cells on `FXFormBaseCell`, you can create an FXForms-compatible cell from scratch by subclassing `UITableViewCell` and adopting the `FXFormFieldCell` protocol.

Your custom cell must have a property called field, of type `FXFormField`. `FXFormField` is a wrapper class used to encapsulate the properties of a field, and also provides a way to set and get the associated form value (via the field.value virtual property). You cannot instantiate `FXFormField` wrappers directly, however the can be accessed and enumerated via methods on the `FXFormController`. `FXFormField` also provides the `-performActionWithResponder:sender:` that you can use to replicate the cascading action selector behavior of the default cells.

Once you have created your custom cell, you can use it as follows:

* If your cell is used only for a few specific fields, you can use the `FXFormFieldCell` property to use it for a particular form field
* If your cell is designed to handle a particular field type (or types), you can tell the formController to use your custom cell class for a particular type using the `-registerCellClass:forFieldType:` method of FXFormController.
* If you want to completely replace all cells with your own classes, use the `-registerDefaultFieldCellClass:` method of `FXFormController`. This replaces all default cell associations for all field types with your new cell class. You can then use `-registerCellClass:forFieldType:` to add additional cell classes for specific types.


Release notes
--------------

Version 1.1.6

- Options fields with numeric values are now correctly displayed
- Action block will now be called when an options field is updated
- Action blocks are no longer called when tapping subform field cells
- Fixed crash when using placeholder values with options fields
- Added FXFormFieldTypeFloat
- Added dependent fields example

Version 1.1.5

- Virtual fields without keys no longer crash when the form object is an NSManagedObject subclass

Version 1.1.4

- FXForms now nils out all control delegates & datasources correctly to prevent crashes when form is dismissed
- The FXFormImagePickerCell image is no longer drawn with incorrect alignment
- FXFormTextViewCell can now display placeholder text when empty

Version 1.1.3

- Using <propertyName>Field method to set form properties is no longer overridden by defaults
- Only mess with the content inset/offset when the view controller is not a UITableViewController
- It should now be easier to use nibs to lay out cell subclasses without losing standard functionality
- Using FXFormFieldTypeLabel now works more consistently

Version 1.1.2

- Fixed incorrect forwarding of scrollViewWillBeginDragging event
- Fields of type FXFormFieldTypeBitfield are now handled correctly again  (broken in 1.1.1)
- It is now possible to create custom cell classes without inheriting all the standard styling logic
- Added example of creating a custom form cell subclass using a nib file (CustomButtonExample)
- FXForms will no longer try to auto-instantiate NSManagedObjects if they are nil (this would crash previously)

Version 1.1.1

- Fixed bug with indexed options fields
- FXFormOptionPickerCell selected index is now set correctly when tabbing between fields

Version 1.1

- Added support for multi-select option fields - just use a collection type such NSArray, NSSet or NSIndexSet for your options field
- Added FXFormFieldTypeBitfield for NS_OPTIONS-type multi-select enum values
- Added FXFormFieldOptionPickerCell as an alternative way to display options fields (does not support multi-select)
- Nested forms now propagate form actions back to their parent form view controller as well as up to the app delegate
- Added parentFormController property to FXFormController
- FXFormField action property is now a block instead a of a selector (can be specified as either in form dictionary)
- Added FXFormFieldPlaceholder value to be displayed when value is nil / empty
- Keyboard will now display "next" in cases where next cell acceptsFirstResponder
- Added FXFormFieldTypeImage and FXFormImagePickerCell
- Added FXFormFieldTypeLongText for multiline text
- Added FXFormFieldValueTransformer for adapting field values for display
- It is now possible to create completely virtual form objects by overriding setValue:forKey: to set properties
- Added FXFormFieldViewController property for specifying custom form field view controllers
- Added additional example projects to demonstrate the new features
- Button-type fields (ones with only an action and no key) now have centered text by default
- It is now possible to override UITableViewCellStyle without subclassing by using "style" keypath in field config

Version 1.0.2

- Fixed crash when attempting to set UITextInputTraits properties on a FXFormTextFieldCell
- Fixed potential crash when numeric field type is used with string properties

Version 1.0.1

- Subform FXFormController instances now correctly inherit registered cells from the parent controller
- Fields of type FXFormFieldOption with associated actions will now still be toggled before action fires

Version 1.0

- Initial release
