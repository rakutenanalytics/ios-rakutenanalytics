source 'https://cdn.cocoapods.org/'
source 'https://gitpub.rakuten-it.com/scm/eco/core-ios-specs.git'

platform :ios, '12.0'
use_frameworks!
inhibit_all_warnings!

abstract_target 'Common' do
  pod 'RAnalyticsBroadcast', :inhibit_warnings => false, :path => './RAnalyticsBroadcast.podspec'
  pod 'OCMock'
  pod 'Kiwi', '~> 3.0'
  pod 'Quick', '~> 5.0'
  pod 'Nimble'
  pod 'ViewInspector'

  target 'UnitTests' do
    pod 'RAnalytics', :inhibit_warnings => false, :path => './RAnalytics.podspec'
  end

  target 'FunctionalTests' do
    pod 'RAnalytics', :inhibit_warnings => false, :path => './RAnalytics.podspec'
  end

  target 'IntegrationTests' do
    pod 'RAnalytics', :inhibit_warnings => false, :path => './RAnalytics.podspec'
  end

  target 'CoreTests' do
    pod 'RAnalytics/Core', :inhibit_warnings => false, :path => './RAnalytics.podspec'
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # This part fixes xcodebuild error during docs generation.
      # See DOCS_GENERATION.md for more details.
      if Gem::Version.new('9.0') > Gem::Version.new(config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
      end
    end
  end
end

# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix:
