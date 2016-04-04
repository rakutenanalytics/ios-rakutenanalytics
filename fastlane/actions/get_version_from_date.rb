module Fastlane
  module Actions
    module SharedValues
      R_VERSION_FROM_DATE = :R_VERSION_FROM_DATE
    end

    class GetVersionFromDateAction < Action
      def self.run(params)
        Helper.log.info "Making up a version from the current date"

        Actions.lane_context[SharedValues::R_VERSION_FROM_DATE] = Actions.sh("/bin/date -u +'1.%-y%m.%-d%H%M%S'").strip!
      end

      def self.description
        "Make up a version using the current date"
      end

      def self.output
        [
          ['R_VERSION_FROM_DATE', 'Version']
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
