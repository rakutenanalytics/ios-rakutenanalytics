require 'fileutils'

module Fastlane
  module Actions
    class BuildFrameworkAction < Action
      def self.run(params)
        UI.message("Build framework")

        frameworkName = params[:framework] || "RAnalytics"
        frameworkFolder = params[:folder] || "RakutenAnalyticsSDK"
        Dir.chdir(frameworkFolder)
        version = params[:version]

        # run build
        UI.message("Building #{frameworkName} v#{version} in folder path #{frameworkFolder}")
        sh "./build-universal-framework.sh"
        UI.success("Successfully built framework")

        suffix = "-v#{version}"
        debug_path = "build/debug/universal"
        release_path = "build/release/universal"
        debug_framework_zip = "#{frameworkName}Debug#{suffix}.zip"
        release_framework_zip = "#{frameworkName}Release#{suffix}.zip"
        debug_symbols_zip = "#{frameworkName}Debug_dSYM#{suffix}.zip"
        release_symbols_zip = "#{frameworkName}Release_dSYM#{suffix}.zip"

        # clean up any old artifacts
        sh "rm -f #{frameworkName}Release*.zip && rm -f #{frameworkName}Debug*.zip"

        # confirm build outputs are present
        sh "ls #{debug_path}/#{frameworkName}.framework && ls #{release_path}/#{frameworkName}.framework"

        # package frameworks as zips, removing paths
        sh "cd #{debug_path} && zip -r ../../../#{debug_framework_zip} #{frameworkName}.framework"
        sh "ls -l #{debug_framework_zip}"
        sh "cd #{release_path} && zip -r ../../../#{release_framework_zip} #{frameworkName}.framework"
        sh "ls -l #{release_framework_zip}"

        # unzip release framework for pod lib linting & local podspecs
        sh "unzip -o #{release_framework_zip}"

        # package symbols as zips, removing paths
        sh "cd #{debug_path} && zip -r ../../../#{debug_symbols_zip} #{frameworkName}.framework.dSYM"
        sh "ls -l #{debug_symbols_zip}"
        sh "cd #{release_path} && zip -r ../../../#{release_symbols_zip} #{frameworkName}.framework.dSYM"
        sh "ls -l #{release_symbols_zip}"

        UI.success("Successfully packaged #{frameworkName} v#{version} ")
      end

      def self.description
        "Build and package public framework for module"
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :version,
                                         description: "Tag to use for naming artifacts",
                                         is_string: true,
                                         optional: false
            ),
            FastlaneCore::ConfigItem.new(key: :framework,
                                         description: "Name of framework to build",
                                         is_string: true,
                                         optional: true
            ),
            FastlaneCore::ConfigItem.new(key: :folder,
                                         description: "Folder in which to run the build script",
                                         is_string: true,
                                         optional: true
            )                        
        ]
      end

      def self.output
      end

      def self.authors
        ["rem"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix: