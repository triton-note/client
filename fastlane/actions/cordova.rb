module Fastlane
  module Actions
    class CordovaAction < Action
      def self.run(params)
        Dir.chdir(FActions.lane_context[Actions::SharedValues::PROJECT_ROOT]) do
          node_modules
          cleanup
          cordova
          ionic
        end
      end

      def self.cleanup
        ['plugins', 'platforms'].each Dir.rmdir
        Dir.mkdir 'plugins'
      end

      def self.cordova
        system("cordova platform add #{ENV['PLATFORM']}")

        plugins = [
          'cordova-plugin-crosswalk-webview@~1.3.1',
          'cordova-plugin-device@~1.0.1',
          'cordova-plugin-console@~1.0.1',
          'cordova-plugin-camera@~1.2.0',
          'cordova-plugin-splashscreen@~2.1.0',
          'cordova-plugin-statusbar@~1.0.1',
          'cordova-plugin-geolocation@~1.0.1',
          'cordova-plugin-whitelist@~1.0.0',
          'phonegap-plugin-push@~1.3.0',
          'https://github.com/sawatani/Cordova-plugin-file.git#GooglePhotos',
          'https://github.com/fathens/Cordova-Plugin-FBConnect.git#feature/ios APP_ID=${FACEBOOK_APP_ID} APP_NAME=${APPLICATION_NAME}',
          'https://github.com/fathens/Cordova-Plugin-Crashlytics.git API_KEY=${FABRIC_API_KEY}'
        ]

        plugins.each do |line|
          names = plugin.split
          vars = []
          names[1..-1].each do |n|
            ns = n.split('=')
            m = /^\${(\w+)}$/.match ns[1]
            if m != nil then
              ns[1] = os.environ[m[1]]
            end
            vars.concat ['--variable', ns.join('=')]
          end
          system("cordova plugin add #{names[0]} #{vars.join(' ')}")
        end
      end

      def self.ionic
        system("ionic resources")
      end

      def self.node_modules
        if !ENV['PATH'].include?('node_modules/.bin') then
          ENV['PATH'] = "#{ENV['PATH']}:#{Dir.pwd}/node_modules/.bin"
        end
        if system('cordova -v') || system('ionic -v') then
          with_cache('node_modules') do
            system('npm install')
          end
        end
      end

      def self.with_cache(name, &block)
        filename = "#{name}.tar.bz2"
        remotename = "s3://${AWS_S3_BUCKET}/${PROJECT_REPO_SLUG}/#{filename}"
        if !File.exist?(name) then
          begin
            system("aws s3 cp #{remotename} #{filename}")
            system("tar jxf #{filename}")
          rescue
            Dir.mkdir(name)
          end
        end
        begin
          block.call
        ensure
          system("tar jcf #{filename} #{name}")
          system("aws s3 cp #{filename} #{remotename}")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Cordova prepare"
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
