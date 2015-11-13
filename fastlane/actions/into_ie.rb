module Fastlane
  module Actions
    class IntoIeAction < Action
      def self.run(params)
        puts "into Isolate Environment"
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "into Isolate Environment"
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
