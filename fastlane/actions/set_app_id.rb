module Fastlane
  module Actions
    class SetAppIdAction < Action
      def self.run(params)
        appId = params[:id]
        target = 'config.xml'
        puts "Setting App ID '#{appId}' to #{target}"

        require 'rexml/document'
        doc = REXML::Document.new(open(target))

        doc.elements['widget'].attributes['id'] = appId
        File.write(target, doc)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Set app ID for config.xml"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :id,
          description: "App ID for config.xml",
          optional: false,
          is_string: true
          )
        ]
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
