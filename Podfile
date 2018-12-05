source 'https://github.com/CocoaPods/Specs.git'
source 'https://gitpub.rakuten-it.com/scm/eco/core-ios-specs.git'

install! 'cocoapods', :deterministic_uuids => false
platform :ios, '10.0'
use_frameworks!

abstract_target 'Common' do
  pod 'RAnalyticsBroadcast', :path => './RAnalyticsBroadcast.podspec'
  pod 'RDeviceIdentifier', :inhibit_warnings => true, :git => 'https://gitpub.rakuten-it.com/scm/eco/ios-deviceid.git'
  pod 'OCMock'
  pod 'OHHTTPStubs'
  pod 'Kiwi', '~> 3.0.0'

  target 'UnitTests' do
    pod 'RAnalytics', :path => './RAnalytics.podspec'
  end

  target 'FunctionalTests' do
      pod 'RAnalytics', :path => './RAnalytics.podspec'
  end

  target 'CoreTests' do
    pod 'RAnalytics/Core', :path => './RAnalytics.podspec'
  end
end

# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix:
