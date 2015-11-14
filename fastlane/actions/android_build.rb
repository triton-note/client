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

        system("cordova build android --release --buildConfig=#{config_file}")
      end

      def self.update_sdk(names)
        if !system("android list sdk") then
          system('brew install android')
          ENV['ANDROID_HOME'] = sh('brew --prefix android')
        end
        names.each do |name|
          system("echo y | android update sdk --no-ui --all --filter #{name} | grep Installed")
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
          lines.each do |line|
            if line.include? key then
              file.puts "#{key}=#{multi}"
            else
              file.puts line
            end
          end
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
