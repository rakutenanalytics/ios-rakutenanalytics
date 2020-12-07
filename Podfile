source 'https://github.com/CocoaPods/Specs.git'
source 'https://gitpub.rakuten-it.com/scm/eco/core-ios-specs.git'

platform :ios, '11.0'
use_frameworks!
inhibit_all_warnings!

abstract_target 'Common' do
  pod 'RAnalyticsBroadcast', :inhibit_warnings => false, :path => './RAnalyticsBroadcast.podspec'
  pod 'RDeviceIdentifier', :git => 'https://gitpub.rakuten-it.com/scm/eco/ios-deviceid.git'
  pod 'RLogger', :git => 'https://gitpub.rakuten-it.com/scm/eco/ios-logger.git'
  pod 'OCMock'
  pod 'OHHTTPStubs', '~> 8.0'
  pod 'Kiwi', '~> 3.0.0'

  target 'UnitTests' do
    pod 'RAnalytics', :inhibit_warnings => false, :path => './RAnalytics.podspec'
  end

  target 'FunctionalTests' do
      pod 'RAnalytics', :inhibit_warnings => false, :path => './RAnalytics.podspec'
  end

  target 'CoreTests' do
    pod 'RAnalytics/Core', :inhibit_warnings => false, :path => './RAnalytics.podspec'
  end
end

# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix:
