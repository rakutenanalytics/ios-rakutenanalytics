Pod::Spec.new do |s|
  s.name         = "RSDKAnalytics"
  s.author       = { "Julien Cayzac" => "julien.cayzac@mail.rakuten.com" }
  s.version      = "2.0.0"
  s.summary      = "Rakuten SDK analytics library"
  s.homepage     = "https://git.dev.rakuten.com/projects/SDK/repos/ios-analytics/"
  s.license      = { :type => 'Proprietary', :file => 'LICENSE' }
  s.source       = { :git => "https://git.dev.rakuten.com/scm/SDK/ios-analytics.git", :tag => s.version.to_s }
  s.platform = :ios, "6.0"
  s.requires_arc = true
  s.xcconfig = {
    'CLANG_ENABLE_MODULES'    => 'YES',
    'CLANG_MODULES_AUTOLINK'  => 'YES',
    'GCC_C_LANGUAGE_STANDARD' => 'gnu99'
  }

  s.source_files  = 'RSDKAnalytics/**/*.{h,m}'
  s.ios.libraries = 'sqlite3', 'z'

  s.dependency 'RSDKSupport/Utilities', '~> 2.2.3'
  s.dependency 'RSDKDeviceInformation', '~> 1.0.0'
  s.dependency 'FXReachability',        '~> 1.1.1'
end

# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix:
# sublime: tab_size 2; translate_tabs_to_spaces true; trim_trailing_white_space_on_save true; trim_automatic_white_space true; x_syntax Packages/Ruby/Ruby.tmLanguage
