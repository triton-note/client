module Fastlane
  module Actions
    class GitLogsAction < Action
      def self.run(params)
        last = last_tag
        logs = []
        obj = CommitObj.new('HEAD')
        if last
          last_sha = CommitObj.new(last).sha
          while obj && obj.sha != last_sha
            parents = obj.parents.sort_by(&:timestamp).reverse
            logs << obj.oneline if parents.size < 2
            obj = parents.first
          end
        else
          logs << obj.oneline
        end
        return logs.join("\n")
      end

      def self.last_tag
        prefix = "deployed/#{ENV['FASTLANE_PLATFORM_NAME']}/#{ENV['BUILD_MODE']}/"
        sh("git tag -l | grep '#{prefix}' || echo").split("\n").sort.last
      end

      class CommitObj
        def initialize(name)
          @name = name
        end

        def sha
          log('%H')
        end

        def parents
          log('%P').split.map { |x| CommitObj.new(x) }
        end

        def timestamp
          log('%at').to_i
        end

        def oneline
          log('[%h] %s')
        end

        def log(format)
          Action.sh("git log #{@name} -n1 --format='#{format}'").strip
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Git logs from previous deploy"
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