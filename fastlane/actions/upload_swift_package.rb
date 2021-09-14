module Fastlane
  module Actions
    class UploadSwiftPackageAction < Action
      def self.run(params)
        isSnapshot = !params[:release]
        version = params[:version]
        target_branch = params[:target_branch] || "master"

        packageSwiftFolder = "RakutenAnalyticsSDK"

        Dir.chdir(packageSwiftFolder) do

          if isSnapshot
            snapshot_repo = "rakutentech/ios-analytics-framework-snapshots"
            UI.message "Uploading snapshot framework v#{version} to GitHub repo: #{snapshot_repo}, branch #{target_branch}"

            sh "sh push_xcframework_snapshot.sh #{version} #{ENV["SNAPSHOT_GITHUB_TOKEN"]} #{target_branch}"

            UI.success "Successfully uploaded snapshot framework v#{version}"
          else
            release_repo = "rakutentech/ios-analytics-framework"
            zipFrameworkPath = "RAnalyticsRelease-v#{version}.zip"

            UI.message "Generating checksum for #{zipFrameworkPath}"
            checksum = sh("swift package compute-checksum #{zipFrameworkPath}").strip

            UI.message "Updating Package.swift file"
            packageUrl = "https://github.com/#{release_repo}/releases/download/#{version}/RAnalyticsRelease-v#{version}.zip"
            sedPatternChecksum = '/^[[:space:]]*name: "RAnalytics"/{n;n;/checksum: / s/"[^"][^"]*"/"'+"#{checksum}"+'"/;}'
            sedPatternUrl = '/^[[:space:]]*name: "RAnalytics"/{n;/url: / s#"[^"][^"]*"#"'+"#{packageUrl}"+'"#;}'
            sh "sed -i '' '#{sedPatternChecksum}' Package.swift"
            sh "sed -i '' '#{sedPatternUrl}' Package.swift"

            updates = File.readlines("Package.swift").grep(/url: "#{packageUrl}"|checksum: "#{checksum}"/)
            UI.user_error!("Package.swift was not updated correctly. Check the file syntax") unless updates.size == 2

            UI.message "Getting exiting Package.swift sha from the repo"
            existingPackageSwiftSha = nil
            GithubApiAction.run(
              api_token: ENV["RELEASE_GITHUB_TOKEN"],
              server_url: "https://api.github.com",
              http_method: "GET",
              path: "/repos/#{release_repo}/contents/Package.swift",
              body: { branch: "#{target_branch}" },
              error_handlers: {
                404 => proc do |result|
                  UI.message("Package.swift doesn't exist in the repo")
                end
              }
            ) do |result|
              json = result[:json]
              UI.message("Found existing Package.swift, sha: #{json["sha"]}")
              existingPackageSwiftSha = json["sha"]
            end

            payload = {
              path: "Package.swift",
              message: "update Package.swift for version #{version}",
              content: Base64.encode64(File.open(File.expand_path("Package.swift")).read),
              branch: target_branch
            }

            unless existingPackageSwiftSha == nil
              payload[:sha] = existingPackageSwiftSha # sha is required for updating
            end

            UI.message "Uploading Package.swift to GitHub repo: #{release_repo}, branch #{target_branch}"
            result = other_action.github_api(
              api_token: ENV["RELEASE_GITHUB_TOKEN"],
              server_url: "https://api.github.com",
              http_method: "PUT",
              path: "/repos/#{release_repo}/contents/Package.swift",
              body: payload
            )

            UI.success "Successfully uploaded Package.swift"
          end
        end
      end

      def self.description
        "For release: Update RAnalytics target in Package.swift file using SDK framework zip file.
        For snapshot: Push updated XCFramework to the snapshot repo. 
        The action requires SNAPSHOT_GITHUB_TOKEN and RELEASE_GITHUB_TOKEN env vars to be set."
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :version,
                                         description: "Tag to use for naming artifacts",
                                         is_string: true,
                                         optional: false
            ),
            FastlaneCore::ConfigItem.new(key: :release,
                                         description: "Sets whether to deploy snapshot (false) or proper release (true)",
                                         is_string: false,
                                         optional: true
            ),
            FastlaneCore::ConfigItem.new(key: :target_branch,
                                         description: "Branch to upload Package.swift file to (master by default)",
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
