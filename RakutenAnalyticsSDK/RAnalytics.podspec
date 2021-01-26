Pod::Spec.new do |s|
    s.name         = "RAnalytics"
    s.version      = "7.0.0"
    s.authors      = { "Rakuten Ecosystem Mobile" => "ecosystem-mobile@mail.rakuten.com" }
    s.summary      = "RAnalytics records user activity and automatically sends tracking events to RAT."
    s.homepage     = "https://www.rakuten.co.jp"
    s.license      = { :type => 'Proprietary', :text => '© Rakuten' }
    s.source       = { :http => "https://github.com/rakutentech/ios-analytics-framework-test/releases/download/0.0.2/RAnalyticsRelease-v0.0.2.zip" }
    s.platform     = :ios, "11.0"
    s.vendored_frameworks = "RAnalytics.framework"
    options = {
      'CLANG_ENABLE_MODULES'    => 'YES',
      'CLANG_MODULES_AUTOLINK'  => 'YES',
      'GCC_C_LANGUAGE_STANDARD' => 'gnu99',
      'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
      'OTHER_CFLAGS'            => "'-DRMSDK_ANALYTICS_VERSION=#{s.version.to_s}'",
      # FIXME: `pod lib lint` attempts to build all available archs.
      # We do not include an arm64 slice in our simulator fat binary therefore 
      # we need to exclude Apple Silicon arm64 arch from simulator builds. 
      # See https://github.com/CocoaPods/CocoaPods/issues/10065#issuecomment-694266259
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }
    s.pod_target_xcconfig  = options
    s.user_target_xcconfig = options
    s.weak_frameworks = [
        'Foundation',
        'UIKit',
        'CoreGraphics',
        'CoreLocation',
        'AdSupport'
      ]
    s.libraries = 'sqlite3', 'z'
end
