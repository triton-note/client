module Fastlane
  module Actions
    class DartAction < Action
      def self.run(params)
        install
        Dir.chdir(Actions.lane_context[Actions::SharedValues::PROJECT_ROOT]) do
          write_settings
          index_download
          build
        end
      end

      def self.install
        if sh("dart --version || echo").strip == "" then
          sh("brew tap dart-lang/dart")
          sh("brew install dart")
        end
      end

      def self.write_settings
        target = File.join('web', 'settings.yaml')
        settings = YAML::load_file(target)

        settings.each do |key, name|
          settings[key] = ENV[name]
        end

        File.open(target, 'w') do |file|
          file.write settings.to_yaml
        end
      end

      def self.index_download
        def download(url, dir)
          def unique_name(base)
            require "digest/md5"
            names = [Digest::MD5.digest(base)]
            m = /.*[^\w]([\w]+)$/.match base.split('?')[0]
            if m != nil then
              names << m[1]
            end
            "cached-#{names.join('.')}"
          end
          name = unique_name(url)
          target = File.join(dir, name)
          Dir.mkdir(dir)
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
            if 0 < --retry_count then
              retry
            else
              raise
            end
          end
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
            filename = download(url, dir)
            target = File.join(dir, filename)
            
            lines = File.open(target) do |file|
              file.readlines              
            end
            
            lines.each do |line|
              m = /(^.*url\()(https:[^\)]+)(\).*)/.match line
              if m != nil then
                loaded = download(m[2], dir)
                line = "#{m[1]}#{loaded}#{m[3]}"
              end
            end
            
            File.open(target) do |file|
              file.write lines.join("\n")
            end
            css['href'] = filename
          end
        end

        File.open(target) do |file|
          file.write doc.to_html
        end
      end

      def self.build
        sh("pub get")
        sh("pub build")
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
