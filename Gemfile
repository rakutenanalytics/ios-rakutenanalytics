source "https://rubygems.org"

# unpin once https://github.com/fastlane/fastlane/issues/19841 is solved
gem "fastlane", "2.200.0"
gem "cocoapods"
gem "cocoapods-user-defined-build-types"
gem "xcode-install"
gem "slather"
gem "jazzy"
gem "danger"
gem "danger-xcov"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
