Pod::Spec.new do |s|
  s.name         = "RAnalytics"
  s.version      = "9.5.0"
  s.authors      = { "Rakuten Ecosystem Mobile" => "ecosystem-mobile@mail.rakuten.com" }
  s.summary      = "SDK that can record user activity and automatically send tracking events to RAT."
  s.homepage     = "https://documents.developers.rakuten.com/ios-sdk/"
  s.license      = { :type => 'Proprietary', :file => 'LICENSE' }
  s.source       = { :git => "https://gitpub.rakuten-it.com/scm/eco/core-ios-analytics.git", :tag => s.version.to_s }
  s.platform     = :ios, "12.0"
  s.requires_arc = true
  s.swift_versions = ['5.4', '5.5']

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
      'Sources/{Main/Core/,Main/Core/Private/,RAnalyticsSwiftLoader/,Main/Util/,Main/util/Private/}*.{h,m,swift}'
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
    ss.dependency 'RSDKUtils', '~> 3.0.0'
    ss.dependency 'RSDKUtils/RLogger', '~> 3.0.0'
    ss.libraries = 'sqlite3', 'z'
  end

  s.subspec 'RAT' do |ss|
    ss.source_files = 'Sources/Main/RAT/**/*.{swift}'
    ss.weak_frameworks = [
      'CoreTelephony',
      'SystemConfiguration'
    ]
    ss.dependency 'RAnalytics/Core'
  end

  s.default_subspecs = 'RAT'
  s.module_map       = 'Sources/RAnalytics.modulemap'
end
# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix:
