Pod::Spec.new do |s|
  s.name         = "RakutenAnalytics"
  s.version      = "10.1.0"
  s.authors      = "Rakuten Analytics"
  s.summary      = "SDK that can record user activity and automatically send tracking events to RAT."
  s.homepage     = "https://github.com/rakutenanalytics/ios-rakutenanalytics"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.source       = { :git => "https://github.com/rakutenanalytics/ios-rakutenanalytics", :tag => s.version.to_s }
  s.platform     = :ios, "12.0"
  s.requires_arc = true
  s.swift_versions = ['5.7.1']
  s.resources = ['Sources/Resources/PrivacyInfo.xcprivacy']

  options = {
    'CLANG_ENABLE_MODULES'    => 'YES',
    'CLANG_MODULES_AUTOLINK'  => 'YES',
    'GCC_C_LANGUAGE_STANDARD' => 'gnu99',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
  }
  s.pod_target_xcconfig  = options
  s.user_target_xcconfig = options

  s.subspec 'Core' do |ss|
    ss.source_files = [
      'Sources/Main/RAnalytics.h',
      'Sources/{Main/Core/,Main/Core/Private/,Main/Core/Geo/,RAnalyticsSwiftLoader/,Main/Util/,Main/Util/Private/,Main/Util/Model/,Main/Util/Optional/,Main/Util/Wrapper/,Main/Util/Extensions/,Main/Util/Lockable/,Main/Util/RLogger/,Main/Util/Networking/,Main/Util/DependencyInjection/,Main/Util/Environment/}*.{m,swift}'
    ]
    ss.private_header_files = 'Sources/Main/Core/{Private,Util}/*.h'
    ss.resource_bundles = { 'RAnalyticsAssets' => ['Sources/Main/Core/Assets/*'] }
    ss.weak_frameworks = [
      'Foundation',
      'UIKit',
      'CoreGraphics',
      'CoreLocation',
      'AdSupport'
    ]
    ss.libraries = 'sqlite3', 'z'
  end

  s.subspec 'RAT' do |ss|
    ss.source_files = 'Sources/Main/RAT/**/*.{swift}'
    ss.weak_frameworks = [
      'CoreTelephony',
      'SystemConfiguration'
    ]
    ss.dependency 'RakutenAnalytics/Core'
  end

  s.default_subspecs = ['RAT']
  s.module_map       = 'Sources/RAnalytics.modulemap'
end
# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix:
