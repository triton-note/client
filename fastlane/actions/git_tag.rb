module Fastlane
  module Actions
    class GitTagAction < Action
      def self.run(params)
        uri = URI("https://api.github.com/repos/#{ENV['PROJECT_REPO_SLUG']}/git/refs")
        data = {
          :ref => "refs/tags/#{params[:tag_name]}",
          :sha => sh('git log HEAD -n1 --format=%H').strip
        }
        headers = {
          "Content-Type" => "application/json",
          "Authorization" => "token #{params[:token]}"
        }
        req = Net::HTTP.new(uri.host, uri.port)
        req.use_ssl = true
        res = req.post(uri.path, data.to_json, headers)
        puts JSON.pretty_generate JSON.load res.body
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Push tag to Github"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :username,
          description: "Github username",
          optional: false,
          is_string: true
          ),
          FastlaneCore::ConfigItem.new(key: :token,
          description: "Github OAuth token",
          optional: false,
          is_string: true
          ),
          FastlaneCore::ConfigItem.new(key: :tag_name,
          description: "Tag name",
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
