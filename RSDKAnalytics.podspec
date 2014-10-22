Pod::Spec.new do |s|
  s.name         = "RSDKAnalytics"
  s.author       = { "Mobile Vision & Product Group | SDTD" => "prj-rmsdk@mail.rakuten.com" }
  s.version      = "2.2.2"
  s.summary      = "Rakuten Mobile SDK's analytics module"
  s.homepage     = "https://rmsdk.azurewebsites.net/"
  s.license      = { :type => 'Proprietary', :file => 'LICENSE' }
  s.source       = { :git => "https://git.rakuten-it.com/scm/SDK/ios-analytics.git", :tag => s.version.to_s }
  s.platform     = :ios, "6.0"
  s.requires_arc = true
  s.xcconfig     = {
    'CLANG_ENABLE_MODULES'    => 'YES',
    'CLANG_MODULES_AUTOLINK'  => 'YES',
    'GCC_C_LANGUAGE_STANDARD' => 'gnu99',
    'OTHER_CFLAGS'            => "'-DRMSDK_ANALYTICS_VERSION=#{s.version.to_s}'"
  }

  s.source_files         = 'RSDKAnalytics/**/*.{h,m}'
  s.private_header_files = 'RSDKAnalytics/RSDKAnalyticsDatabase.h'
  s.ios.libraries        = 'sqlite3', 'z'

  s.dependency 'RSDKSupport/Utilities', '~> 2.1.4'
  s.dependency 'RSDKDeviceInformation', '~> 1.1.2'
end

# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix:
# sublime: tab_size 2; translate_tabs_to_spaces true; trim_trailing_white_space_on_save true; trim_automatic_white_space true; x_syntax Packages/Ruby/Ruby.tmLanguage
