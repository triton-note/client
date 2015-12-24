module Fastlane
  module Actions
    class ReleaseNoteAction < Action
      def self.run(params)
        format = params[:line_format]
        format ||= '[%h] %s'
        
        last = last_tag
        logs = []
        obj = CommitObj.new('HEAD')
        if last
          last_sha = CommitObj.new(last).sha
          while obj && obj.sha != last_sha
            parents = obj.parents.sort_by(&:timestamp).reverse
            logs << obj.log(format) if parents.size < 2
            obj = parents.first
          end
        else
          logs << obj.log(format)
        end
        note = logs.join("\n")

        puts "#### RELEASE_NOTE ####\n" + note
        if note && !note.empty? then
          target = '.release_note'
          File.write(target, note)
          ENV["RELEASE_NOTE_PATH"] = File.absolute_path target
        end
      end

      def self.last_tag
        sh("git fetch")
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
        [
          FastlaneCore::ConfigItem.new(key: :line_format,
          description: "Format of each line. default: '[%h] %s'",
          optional: true,
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