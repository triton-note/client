module Fastlane
  module Actions
    class AndroidBuildAction < Action
      def self.run(params)
        update_sdk(params[:sdks] || [])
        build_num

        config_file = Dir.chdir(File.join('platforms', 'android')) do
          multi_apks(params[:multi_apks])
          keystore(params[:keystore])
        end

        sh("cordova build android --release --buildConfig=#{config_file}")
      end

      def self.update_sdk(names)
        begin
          content = sh('android list sdk --extended')
        rescue
          system('brew install android')
          ENV['ANDROID_HOME'] = sh('brew --prefix android')
          retry
        end

        availables = content.split("\n").map { |line|
          /^id: +\d+ or "(.*)"$/.match line
        }.compact.map { |m| m[1] }

        names.each do |name|
          puts "Checking SDK: #{name}"
          availables.select { |x| x.start_with?(name) }.each do |key|
            puts "Installing SDK #{key}"
            system("echo y | android update sdk --no-ui --all --filter #{key} | grep Installed")
          end
        end
      end

      def self.build_num
        v = ENV["BUILD_NUM"]
        if v != nil then
          num = "#{v}00"
          target = 'config.xml'
          puts "Setting build number '#{num}' to #{target}"

          require 'rexml/document'
          doc = REXML::Document.new(open(target))

          doc.elements['widget'].attributes['android-versionCode'] = num
          File.open(target, 'w') do |file|
            file.puts doc
          end
        end
      end

      def self.keystore(file)
        data = {:android => {:release =>{
          :keystore => file,
          :storePassword => ENV['ANDROID_KEYSTORE_PASSWORD'],
          :alias => ENV['ANDROID_KEYSTORE_ALIAS'],
          :password => ENV['ANDROID_KEYSTORE_ALIAS_PASSWORD']
          }}}

        target = 'build.json'
        puts "Writing #{target}"
        File.open(target, 'w') do |file|
          JSON.dump(data, file)
        end

        File.absolute_path target
      end

      def self.multi_apks(multi)
        key = 'cdvBuildMultipleApks'

        target = 'gradle.properties'
        lines = File.exist?(target) ? File.readlines(target) : []

        File.open(target, 'w+') do |file|
          lines.reject { |line| line.include?(key) }.each do |line|
            file.puts line
          end
          file.puts "#{key}=#{multi}"
        end

        File.absolute_path target
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Android Build"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :sdks,
          description: "Array of sdk names",
          optional: true,
          is_string: false
          ),
          FastlaneCore::ConfigItem.new(key: :keystore,
          description: "Absolute path to keystore",
          optional: false,
          is_string: false
          ),
          FastlaneCore::ConfigItem.new(key: :multi_apks,
          description: "Boolean for build multiple apks",
          optional: false,
          is_string: false
          )
        ]
      end

      def self.authors
        ["Sawatani"]
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
