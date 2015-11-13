module Fastlane
  module Actions
    class CordovaAction < Action
      def self.run(params)
        puts "Cordova"
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Cordova prepare"
      end

      def self.available_options
        []
      end

      def self.authors
        ["Sawatani"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
