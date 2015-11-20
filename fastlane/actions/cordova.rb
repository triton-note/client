module Fastlane
  module Actions
    class CordovaAction < Action
      def self.run(params)
        node_modules
        cordova(params[:plugins] || [])
        ionic
      end

      def self.cordova(plugins)
        dirs = ['plugins', File.join('platforms', ENV["FASTLANE_PLATFORM_NAME"])]
        if !dirs.all? { |x| File.exist? x } then
          dirs.each do |dir|
            puts "Deleting dir: #{dir}"
            FileUtils.rm_rf dir
          end
          Dir.mkdir dirs.first
          return true

          system("cordova platform add #{ENV["FASTLANE_PLATFORM_NAME"]}")

          plugins.each do |line|
            system("cordova plugin add #{line}")
          end
        end
      end

      def self.ionic
        if !File.exist? File.join('resources', ENV["FASTLANE_PLATFORM_NAME"])
          system("ionic resources")
        end
      end

      def self.node_modules
        if !ENV['PATH'].include?('node_modules/.bin') then
          ENV['PATH'] = "#{ENV['PATH']}:#{Dir.pwd}/node_modules/.bin"
        end
        if !(system('cordova -v') && system('ionic -v')) then
          with_cache('node_modules') do
            system('npm install')
          end
        end
      end

      def self.with_cache(name, &block)
        remotename = "s3://${AWS_S3_BUCKET}/${PROJECT_REPO_SLUG}/#{name}.tar.bz2"
        if !File.exist?(name) then
          begin
            puts "Loading #{name}"
            system("aws s3 cp #{remotename} - | tar jxf -")
          rescue
            Dir.mkdir(name)
          end
        end
        begin
          block.call
        ensure
          pid = Process.spawn("tar jcf - #{name}  | aws s3 cp - #{remotename}")
          puts "Saving #{name} (on pid:#{pid})"
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Cordova prepare"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :plugins,
          description: "Array of plugins",
          optional: true,
          is_string: false
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
