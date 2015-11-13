module Fastlane
  module Actions
    module SharedValues
      BUILD_MODE = :BUILD_MODE
      PERSISTENT_DIR = :PERSISTENT_DIR
      PROJECT_ROOT = :PROJECT_ROOT
    end

    class IntoIeAction < Action
      def self.run(params)
        Actions.lane_context[Actions::SharedValues::PROJECT_ROOT] = File.dirname(Fastlane::FastlaneFolder.path)

        Dir.chdir(Actions.lane_context[Actions::SharedValues::PROJECT_ROOT]) do
          Actions.lane_context[Actions::SharedValues::PERSISTENT_DIR] = File.join(Fastlane::FastlaneFolder.path, 'persistent')
          Actions.lane_context[Actions::SharedValues::BUILD_MODE] = get_build_mode
        end
      end

      def self.get_build_mode
        branch = ENV['GIT_BRANCH'] || sh('git symbolic-ref HEAD --short 2>/dev/null').strip

        map = {
          "release" => "BRANCH_RELEASE",
          "debug" => "BRANCH_DEBUG",
          "beta" => "BRANCH_BETA"
        }

        map.keys.find  do |key|
          pattern = ENV[map[key]]
          if pattern != nil then
            puts "Checking build mode of branch '#{branch}' with '#{pattern}'"
            Regexp.new(pattern).match branch
          end
        end || "test"
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
