Pod::Spec.new do |s|
  s.name         = "RAnalyticsBroadcast"
  s.version      = "1.0.0"
  s.authors      = { "Rakuten Ecosystem Mobile" => "ecosystem-mobile@mail.rakuten.com" }
  s.summary      = "Analytics broadcast module of the Rakuten Ecosystem Mobile SDK"
  s.homepage     = "https://documents.developers.rakuten.com/ios-sdk/"
  s.license      = { :type => 'Proprietary', :file => 'LICENSE' }
  s.source       = { :git => "https://gitpub.rakuten-it.com/scm/eco/core-ios-analytics.git", :tag => 'broadcast-'+s.version.to_s }
  s.platform     = :ios, "7.0"
  s.requires_arc = true
  
  options = {
    'CLANG_ENABLE_MODULES'    => 'YES',
    'CLANG_MODULES_AUTOLINK'  => 'YES',
    'GCC_C_LANGUAGE_STANDARD' => 'gnu99',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'OTHER_CFLAGS'            => "'-DRMSDK_ANALYTICSBROADCAST_VERSION=#{s.version.to_s}'"
  }
  s.pod_target_xcconfig  = options
  s.user_target_xcconfig = options

  s.source_files         = 'RAnalyticsBroadcast/**/*.{h,m}'
  s.module_map           = 'RAnalyticsBroadcast/RAnalyticsBroadcast.modulemap'
end
# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix:
