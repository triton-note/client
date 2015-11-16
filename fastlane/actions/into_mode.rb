module Fastlane
  module Actions
    class IntoModeAction < Action
      def self.run(params)
        if !ENV['BUILD_MODE']
          branch = ENV['GIT_BRANCH'] || sh('git symbolic-ref HEAD --short 2>/dev/null').strip

          map = {
            "release" => "BRANCH_RELEASE",
            "debug" => "BRANCH_DEBUG",
            "beta" => "BRANCH_BETA"
          }

          ENV['BUILD_MODE'] = map.keys.find  do |key|
            pattern = ENV[map[key]]
            if pattern != nil then
              puts "Checking build mode of branch '#{branch}' with '#{pattern}'"
              Regexp.new(pattern).match branch
            end
          end || "test"
        end
        puts "Running on '#{ENV['BUILD_MODE']}' mode"
        LaneManager.load_dot_env(ENV['BUILD_MODE'])
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
