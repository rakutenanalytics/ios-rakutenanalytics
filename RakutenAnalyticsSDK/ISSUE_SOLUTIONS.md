# Issues and Solutions

## Embedding private frameworks

### Outline
The SDK has dependencies that are held in private repositories and their source cannot be exposed as public.
Also some teams don't have an access to those repositories.
There are few solutions for that.

### Solutions
* **Solution 1 - static library**   
A dependency can be exported as a static library which after deployment it becomes a part of the SDK's binary file.
To achieve that effect, those pod dependencies must be built as a static framework even if there's swift code inside.<br/>
(Error: `Using Swift static libraries with custom module maps is currently not supported. Please build 'RAnalytics' as a framework or remove the custom module map.`<br/>)
This plugin can be used to make required pods static frameworks and fix above error:<br/>
https://github.com/joncardasis/cocoapods-user-defined-build-types<br/>
Podfile:
```ruby
plugin 'cocoapods-user-defined-build-types'
enable_user_defined_build_types!

source 'https://cdn.cocoapods.org/'
source 'https://gitpub.rakuten-it.com/scm/eco/core-ios-specs.git'
 
platform :ios, '11.0'
inhibit_all_warnings!
 
workspace 'RakutenAnalyticsSDK'
 
target 'RAnalytics' do
  pod 'RLogger', :build_type => :static_framework
  pod 'RDeviceIdentifier', :build_type => :static_framework
end
```

* ~~**Solution 2 - umbrella framework**~~    

###### Unfortunately with this solution private frameworks must be signed manually before deploying an app that has RAnalytics SDK dependency

_Note:_ Umbrella frameworks are officialy not supported on iOS<br/>
https://developer.apple.com/library/archive/technotes/tn2435/_index.html#//apple_ref/doc/uid/DTS40017543-CH1-PROJ_CONFIG-APPS_WITH_DEPENDENCIES_BETWEEN_FRAMEWORKS

This solution is about embedding pod generated frameworks as a dynamic frameworks inside RAnalytics framework.
Umbrella frameworks are commonly used by Apple in their frameworks. Here we are going to create something alike.
First, we are going to modify Podfile so it creates a workspace with Pods and RAnalytics project without linking.
```ruby
...
use_frameworks!
workspace 'RakutenAnalyticsSDK'

# We want pods to be just built without linking them to RAnalytics project
abstract_target 'Global' do
  pod 'RLogger'
  pod 'RDeviceIdentifier'
end
 
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      ...
      # This fixes '<module_name> was not compiled with library evolution support' warning
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'    
    end
  end

  # RAnalytics project must be added manually to the workspace because it's not linked to any pod
  workspace = Xcodeproj::Workspace.new_from_xcworkspace('RakutenAnalyticsSDK.xcworkspace')
  proj_ref = Xcodeproj::Workspace::FileReference.new('RAnalytics.xcodeproj')  
  unless workspace.include?(proj_ref) 
    workspace << 'RAnalytics.xcodeproj' 
    workspace.save_as('RakutenAnalyticsSDK.xcworkspace')
  end
end
```
Then the products (frameworks) in Pods project must be linked manually to the RAnalytics project:
* Drag&drop built frameworks to "Frameworks and Libraries" section in General tab in RAnalytics project settings
* Add a Copy Files Phase that copies those frameworks (destination - Frameworks)
* Add `$(BUILT_PRODUCTS_DIR)/<module_name>` paths to Framework Search Paths property in build settings

(Here's a link that describes similar, more complex process: https://medium.com/@andreamiotz/ios-umbrella-framework-with-cocoapods-57d2d3c2daa9)

**NOTE:** Be sure to update the unversal framework build script to include all architectures in sub-frameworks.<br/>
Example:
```bash
frameworkDependenciesPath="RAnalytics.framework/Frameworks"
for dependencyPath in $BUILD_DEBUG_SIMULATOR/$frameworkDependenciesPath/*/; do
  dependency=`basename $dependencyPath`
  dependencyName="${dependency%.framework}"
  lipo -create \
  $BUILD_DEBUG_SIMULATOR/$frameworkDependenciesPath/$dependency/$dependencyName \
  $BUILD_DEBUG_DEVICE/$frameworkDependenciesPath/$dependency/$dependencyName \
  -output $BUILD_DEBUG_UNIVERSAL/$frameworkDependenciesPath/$dependency/$dependencyName
done
```

* **Solution 3 - XCFramework**  
The XCFramework is a new framework format introduced in Xcode 11. It provides a simple way to create a framework for all architectures (no more `lipo`) making the deployment process easier.

Here is a very intelligible description and demonstration of XCFrameworks: https://github.com/bielikb/xcframeworks

Unfortunately XCFramework cannot contain another frameworks/dependencies (they would have to be linked, loaded and signed manually). But the new format can be combined with approach described in Solution 1 in order to embed private dependencies as a one framework.

To create a RAnalytics XCFramework, two frameworks, one for device and one for simulator, must be built and then combined into one xcframework using this command:
```bash
xcodebuild -create-xcframework \
    -framework $derivedDataPathSimulator/RAnalytics.framework \
    -framework $derivedDataPathDevice/RAnalytics.framework \
    -output $OUTPUT_FOLDER/$scheme/$FRAMEWORK_NAME.xcframework
```
The whole process can be found in `build-xcframework.sh` script file.

**NOTE:** In XCode 12 dSYM and bitcode symbol files can be integrated into XCFramework using `-debug-symbols` parameter. We don't use it intentionally to keep the symbols in a separate location and not expose them to public user.


#### Private framework import issues in Swift files
With above Solutions 1 and 2, if SDK contains Swift files that import those private frameworks, after building framework and adding it to a client project, there is an error in the SDK's source file stating that module, linked to the private framework, cannot be retrieved.

One way to fix that is to modify source code by creating a wrapper that will call a private module dynamically. Using that wrapper will avoid importing that module.

Here is an example of `RLogger` module wrapper:
```swift
import Foundation

/// A Log Wrapper.
@objc public final class LogWrapper: NSObject {}

extension LogWrapper {
    /// Log with RLogger.
    /// - Parameters:
    ///     - level: the logging level.
    ///     - format: the message format.
    ///     - arguments: the message arguments.
    /// - Returns: the logged message or nil.
    /// - Note: "import RLogger" is hidden so the public `RAnalytics` framework can be built without requiring `RLogger` module.
    static func log(_ level: RAnalyticsLoggingLevel, format: String, arguments: CVarArg...) -> String? {
        let rloggerClass = NSClassFromString("RLogger") as? NSObject.Type
        let sel = Selector(("log:message:"))
        let result = rloggerClass?.perform(sel, with: level, with: String(format: format, arguments: arguments))?.takeUnretainedValue()
        return result as? String
    }
}
```

Another way, that does not require modifying source code, is to add a private modulemap file:
```ruby
module RLogger {
    link "RLogger"
}
```
This modulemap will fix the linking problem for client projects that use the SDK.
A path to private modulemap file must be defined in main target build settings under "Private Module Map File" property.

Here are some articles and documentation that are related to this solution:<br/>
https://clang.llvm.org/docs/Modules.html#module-map-language (Private module section)<br/>
https://medium.com//link-static-c-library-to-swift-framework-as-a-private-module-97eae2fec75e<br/>
https://medium.com/5-minute-break-while-coding/creating-swift-framework-with-private-objective-c-members-the-good-the-bad-and-the-ugly-4d726386644b
