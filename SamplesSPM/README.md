# RAnalyticsSampleSPM
## Description
This sample is based on the RAnalytics framework snapshots.

This RAnalytics framework is used for internal testing of pre-release snapshots in the SDK team.

## Issues
If you can't checkout the RAnalytics framework in Xcode, please execute these 2 command lines:

```
/usr/libexec/Plistbuddy -c "Add :IDEPackageSupportUseBuiltinSCM bool 1" ~/Library/Preferences/com.apple.dt.Xcode.plist
xcodebuild -scheme RAnalyticsSampleSPM -resolvePackageDependencies -usePackageSupportBuiltinSCM
```
