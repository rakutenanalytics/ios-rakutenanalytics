Pod::Spec.new do |s|
  s.name         = "RSDKAnalytics"
  s.version      = "2.6.0"
  s.authors      = { "Rakuten Ecosystem Mobile" => "ecosystem-mobile@mail.rakuten.com" }
  s.summary      = "Analytics module of the Rakuten Ecosystem Mobile SDK"
  s.homepage     = "https://www.raksdtd.com/"
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

  s.weak_frameworks      = [
    'Foundation',
    'UIKit',
    'CoreGraphics',
    'CoreLocation',
    'CoreTelephony',
    'SystemConfiguration',
    'AdSupport'
  ]
  s.libraries            = 'sqlite3', 'z'
  s.source_files         = 'RSDKAnalytics/**/*.{h,m}'
  s.private_header_files = [
    'RSDKAnalytics/Private/**/*.h'
  ]
  s.resource_bundles = {
    'RSDKAnalyticsAssets' => ['RSDKAnalytics/Assets/*']
  }
  s.module_map           = 'RSDKAnalytics/RSDKAnalytics.modulemap'

  s.dependency 'RSDKDeviceInformation', '~> 1.4'
end
# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix:
