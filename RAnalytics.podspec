Pod::Spec.new do |s|
  s.name         = "RAnalytics"
  s.version      = "1.0.0"
  s.summary      = "Rakuten SDK analytics framework."
  s.homepage     = "https://git.dev.rakuten.com/projects/SDK/repos/ios-analytics"
  s.license      = { :type => 'Proprietary', :file => 'LICENSE' }
  s.author       = { "Mandar" => "mandarka@cybage.com" }
  s.platform     = :ios, "4.3"
  s.source       = { :git => "https://git.dev.rakuten.com/scm/sdk/ios-analytics.git", :tag => s.version.to_s }
  s.source_files  = 'RakutenAnalytic/**/*.{h,m}', 'RCommonUtilities/**/*.{h,m}'
  s.ios.frameworks = 'CFNetwork', 'CoreLocation', 'CoreTelephony', 'Security', 'SystemConfiguration'
  s.ios.libraries = 'sqlite3.0', 'z.1.2.5'
  s.requires_arc = true
  s.dependency 'SBJson', '~> 3.2'
  s.dependency 'FXReachability', '~> 1.1'
end

