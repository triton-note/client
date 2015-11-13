module Fastlane
  module Actions
    class DartAction < Action
      def self.run(params)
        puts "Dart"
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Dart Build"
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
