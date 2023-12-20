# RAnalyticsSampleSPM
## Description
This sample is based on the internal RAnalytics Swift Package.

This internal RAnalytics Swift Package is used for internal testing of internal pre-release in the SDK team.

## Issues
If you can't checkout the RAnalytics Swift Package in Xcode, please execute these 2 command lines:

```
/usr/libexec/Plistbuddy -c "Add :IDEPackageSupportUseBuiltinSCM bool 1" ~/Library/Preferences/com.apple.dt.Xcode.plist
xcodebuild -scheme RAnalyticsSampleSPM -resolvePackageDependencies -usePackageSupportBuiltinSCM
```
