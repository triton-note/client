module Fastlane
  module Actions
    class AndroidDeployAction < Action
      def self.run(params)
        if params[:multi_apks] then
          googleplay
        else
          crashlytics
        end
      end

      def self.crashlytics
        File.open('fabric.properties', 'a') do |file|
          file.puts "betaDistributionGroupAliases=#{ENV['FABRIC_CRASHLYTICS_GROUPS']}" if ENV['FABRIC_CRASHLYTICS_GROUPS']
          file.puts "betaDistributionReleaseNotesFilePath=#{ENV['RELEASE_NOTE_PATH']}" if ENV['RELEASE_NOTE_PATH']
        end
        sh('./gradlew crashlyticsUploadDistributionRelease')
      end

      def self.googleplay
        # TODO
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Android Build"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :multi_apks,
          description: "Boolean for build multiple apks",
          optional: false,
          is_string: false
          )
        ]
      end

      def self.authors
        ["Sawatani"]
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end