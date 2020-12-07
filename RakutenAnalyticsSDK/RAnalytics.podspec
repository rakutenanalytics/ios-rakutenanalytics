Pod::Spec.new do |s|
    s.name         = "RAnalytics"
    s.version      = "6.0.0"
    s.authors      = { "Rakuten Ecosystem Mobile" => "ecosystem-mobile@mail.rakuten.com" }
    s.summary      = "RAnalytics records user activity and automatically send tracking events to RAT."
    s.homepage     = "https://www.rakuten.com"
    s.license      = { :type => 'Proprietary', :text => '© Rakuten' }
    s.source       = { :git => "https://github.com/rakutentech/ios-analytics-framework-test.git", :tag => "#{s.version}" }
    s.platform     = :ios, "11.4"
    s.public_header_files = "RAnalytics/RAnalytics.framework/Headers/*.h"
    s.source_files = "RAnalytics/RAnalytics.framework/Headers/*.h"
    s.vendored_frameworks = "RAnalytics/RAnalytics.framework"

    options = {
      'CLANG_ENABLE_MODULES'    => 'YES',
      'CLANG_MODULES_AUTOLINK'  => 'YES',
      'GCC_C_LANGUAGE_STANDARD' => 'gnu99',
      'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
      'OTHER_CFLAGS'            => "'-DRMSDK_ANALYTICS_VERSION=#{s.version.to_s}'"
    }
    s.pod_target_xcconfig  = options
    s.user_target_xcconfig = options
    
    s.subspec 'Core' do |ss|
      ss.source_files = "RAnalytics/RAnalytics.framework/Headers/*.h"
      ss.public_header_files = "RAnalytics/RAnalytics.framework/Headers/*.h"
      ss.weak_frameworks = [
        'Foundation',
        'UIKit',
        'CoreGraphics',
        'CoreLocation',
        'AdSupport'
      ]
      ss.libraries = 'sqlite3', 'z'
  end
end
