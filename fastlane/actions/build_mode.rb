module Fastlane
  module Actions
    class BuildModeAction < Action
      def self.run(params)
        branch = ENV['GIT_BRANCH'] || sh('git symbolic-ref HEAD --short 2>/dev/null').strip

        map = {
          "release" => "BRANCH_RELEASE",
          "debug" => "BRANCH_DEBUG",
          "beta" => "BRANCH_BETA"
        }

        mode = map.keys.find  do |key|
          pattern = ENV[map[key]]
          if pattern != nil then
            puts "Checking build mode of branch '#{branch}' with '#{pattern}'"
            Regexp.new(pattern).match branch
          end
        end || "test"
        
        puts "Running on '#{mode}' mode"
        LaneManager.load_dot_env(mode)

        return mode
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
