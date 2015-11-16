module Fastlane
  module Actions
    class DartAction < Action
      def self.run(params)
        Dir.chdir('dart') do
          write_settings
          index_download
          pub_build
        end
      end

      def self.write_settings
        require 'yaml'

        target = File.join('web', 'settings.yaml')
        settings = YAML::load_file(target)

        settings.each do |key, name|
          m = /^\${(\w+)}$/.match name
          if m && ENV.has_key?(m[1]) then
            settings[key] = ENV[m[1]]
          end
        end

        puts "Rewriting #{target}"
        File.open(target, 'w') do |file|
          file.write settings.to_yaml
        end
      end

      def self.index_download
        cache_digest = lambda do |url, dir|
          require "digest/md5"
          names = [Digest::MD5.hexdigest(url)]
          m = /.*[^\w]([\w]+)$/.match url.split('?')[0]
          if m != nil then
            names << m[1]
          end
          name = "cached-#{names.join('.')}"
          target = File.join(dir, name)
          if !File.exist?(dir) then
            Dir.mkdir(dir)
          end
          retry_count = 3
          begin
            puts "Downloading #{url} to #{target}"
            File.write(target, Net::HTTP.get(URI(url)))
          rescue
            puts "Error on downloading"
            retry_count -= 1
            if 0 < retry_count then
              retry
            else
              raise
            end
          end
          return name
        end

        require 'nokogiri'
        target = File.join('web', 'index.html')
        doc = File.open(target) do |file|
          Nokogiri::HTML(file)
        end

        doc.xpath("//link[@rel='stylesheet']").each do |css|
          href = css['href']
          if /^https:\/\/fonts.googleapis.com\/css\?.*$/.match href then
            dir = File.join('web', 'styles', 'fonts')
            filename = cache_digest.call(href, dir)

            File.open(File.join(dir, filename), 'r+') do |file|
              lines = file.readlines
              file.seek(0)

              lines.each do |line|
                m = /(^.*url\()(https:[^\)]+)(\).*)/.match line
                if m != nil then
                  loaded = cache_digest.call(m[2], dir)
                  line = "#{m[1]}#{loaded}#{m[3]}"
                end
                file.puts line
              end
              file.flush
              file.truncate(file.pos)
            end

            css['href'] = 'styles/fonts/' + filename
          end
        end

        doc.xpath("//script[@type='text/javascript']").each do |js|
          href = js['src']
          if /^https:\/\/.*\.js$/.match(href) then
            js['src'] = 'js/' + cache_digest.call(href, File.join('web', 'js'))
          end
        end

        puts "Rewriting #{target}"
        File.open(target, 'w') do |file|
          file.write doc.to_html
        end
      end

      def self.pub_build
        if File.directory? File.join('build', 'web') then
          puts "Skipping dart build"
        else
          system('type brew')
          system('brew --version')
          if !system("dart --version") then
            puts "Installing dart..."
            system('brew tap dart-lang/dart')
            system('brew install dart')
          end
          puts "Dart Building..."
          system("pub get")
          system("pub build")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Dart Build"
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
