module Fastlane
  module Actions
    module SharedValues
      R_CHANGELOG_FROM_GIT = :R_CHANGELOG_FROM_GIT
    end

    class GetChangelogFromGitAction < Action
      def self.run(params)
        changelog = Actions.sh('/usr/bin/git log -n 20 --date=short --pretty=tformat:"%ad [%h] %w(0,0,4)%B" --no-merges | /usr/bin/sed -E \'s/[[:space:]\n\r]*Change-Id: [[:alnum:]]*[[:space:]\r\n]*//g\' | /usr/bin/grep -vE \'^[[:space:]]*$\'')

        if ENV['BUILD_TAG']
          changelog = "Build tag: #{ENV['BUILD_TAG']}\n\n#{changelog}"
        else
          commit = Actions.sh("/usr/bin/git rev-parse --short HEAD").strip!
          changelog = "Commit: #{commit}\n\n#{changelog}"
        end

        Actions.lane_context[SharedValues::R_CHANGELOG_FROM_GIT] = changelog
      end

      def self.description
        "Reads git history"
      end

      def self.output
        [
          ['R_CHANGELOG_FROM_GIT', 'History from git']
        ]
      end

      def self.authors
        ["jcayzac"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end

# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix:
