source 'https://github.com/CocoaPods/Specs.git'
source 'https://gitpub.rakuten-it.com/scm/eco/core-ios-specs.git'

install! 'cocoapods', :deterministic_uuids => false
platform :ios, '8.0'
use_frameworks!

abstract_target 'Common' do
  pod 'RAnalyticsBroadcast', :path => './RAnalyticsBroadcast.podspec'
  pod 'RDeviceIdentifier', :inhibit_warnings => true, :git => 'https://gitpub.rakuten-it.com/scm/eco/ios-deviceid.git'
  pod 'OCMock'
  pod 'OHHTTPStubs'

  target 'Tests' do
    pod 'RAnalytics', :path => './RAnalytics.podspec'
    pod 'Kiwi', '~> 3.0.0'
  end

  target 'CoreTests' do
    pod 'RAnalytics/Core', :path => './RAnalytics.podspec'
  end
end

# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix:
