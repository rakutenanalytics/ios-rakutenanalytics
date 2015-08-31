Pod::Spec.new do |s|
  s.name         = "RSDKAnalytics"
  s.authors      = { "Mobile Standards Group | SDTD" => "prj-rmsdk@mail.rakuten.com" }
  s.version      = "2.5.1"
  s.summary      = "Rakuten Mobile SDK's analytics module"
  s.homepage     = "https://rmsdk.apps.global.rakuten.com/"
  s.license      = { :type => 'Proprietary', :file => 'LICENSE' }
  s.source       = { :git => "https://gitpub.rakuten-it.com/scm/eco/core-ios-analytics.git", :tag => s.version.to_s }
  s.platform     = :ios, "7.0"
  s.requires_arc = true
  s.xcconfig     = {
    'CLANG_ENABLE_MODULES'    => 'YES',
    'CLANG_MODULES_AUTOLINK'  => 'YES',
    'GCC_C_LANGUAGE_STANDARD' => 'gnu99',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'OTHER_CFLAGS'            => "'-DRMSDK_ANALYTICS_VERSION=#{s.version.to_s}'"
  }

  s.source_files         = 'RSDKAnalytics/**/*.{h,m}'
  s.private_header_files = 'RSDKAnalytics/RSDKAnalyticsDatabase.h'
  s.ios.libraries        = 'sqlite3', 'z'
  s.module_map           = 'RSDKAnalytics/RSDKAnalytics.modulemap'

  s.dependency 'RakutenAPIs',           '~> 1.2'
  s.dependency 'RSDKDeviceInformation', '~> 1.4'
end
# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix:
