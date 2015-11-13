module Fastlane
  module Actions
    class DartAction < Action
      def self.run(params)
        install
        Dir.chdir(File.join(Actions.lane_context[Actions::SharedValues::PROJECT_ROOT], 'dart')) do
          if !File.directory? File.join('build', 'web') then
            write_settings
            index_download
            build
          end
        end
      end

      def self.install
        if !system("dart --version") then
          system("brew tap dart-lang/dart")
          system("brew install dart")
        end
      end

      def self.write_settings
        require 'yaml'

        target = File.join('web', 'settings.yaml')
        settings = YAML::load_file(target)

        settings.each do |key, name|
          if name && ENV.has_key?(name) then
            settings[key] = ENV[name]
          end
        end

        File.open(target, 'w') do |file|
          file.write settings.to_yaml
        end
      end

      def self.index_download
        require 'nokogiri'
        target = File.join('web', 'index.html')
        doc = File.open(target) do |file|
          Nokogiri::HTML(file)
        end

        doc.xpath("//link[@rel='stylesheet']").each do |css|
          href = css['href']
          if /^https:\/\/fonts.googleapis.com\/css\?.*$/.match href then
            dir = File.join('web', 'styles', 'fonts')
            filename = download(href, dir)

            File.open(File.join(dir, filename), 'r+') do |file|
              lines = file.readlines
              file.seek(0)

              lines.each do |line|
                m = /(^.*url\()(https:[^\)]+)(\).*)/.match line
                if m != nil then
                  loaded = download(m[2], dir)
                  line = "#{m[1]}#{loaded}#{m[3]}"
                end
                file.puts line
              end
              file.flush
              file.truncate(file.pos)
            end

            css['href'] = File.join('styles', 'fonts', filename)
          end
        end

        doc.xpath("//script[@type='text/javascript']").each do |js|
          href = js['src']
          if /^https:\/\/.*\.js$/.match(href) then
            js['src'] = File.join('js', download(href, File.join('web', 'js')))
          end
        end

        File.open(target, 'w') do |file|
          file.write doc.to_html
        end
      end

      def self.download(url, dir)
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
          require 'open-uri'
          puts "Downloading #{url} to #{target}"
          open(target, 'wb') do |file|
            open(url, 'rb') do |res|
              file.write res.read
            end
          end
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

      def self.build
        system("pub get")
        system("pub build")
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
