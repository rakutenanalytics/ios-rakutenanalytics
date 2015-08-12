Pod::Spec.new do |s|
  s.name         = "RSDKAnalytics"
  s.author       = { "Mobile Vision & Product Group | SDTD" => "prj-rmsdk@mail.rakuten.com" }
  s.version      = "2.5.0"
  s.summary      = "Rakuten Mobile SDK's analytics module"
  s.homepage     = "https://rmsdk.azurewebsites.net/"
  s.license      = { :type => 'Proprietary', :file => 'LICENSE' }
  s.source       = { :git => "https://git.rakuten-it.com/scm/SDK/ios-analytics.git", :tag => s.version.to_s }
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

  s.dependency 'RakutenAPIs',           '~> 1.2'
  s.dependency 'RSDKDeviceInformation', '~> 1.4'
end
# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix:
