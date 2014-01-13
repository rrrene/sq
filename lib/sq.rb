# -*- coding: UTF-8 -*-

require 'uri'
require 'open-uri'
require 'nokogiri'
require 'fileutils'
require File.expand_path(File.dirname __FILE__) + '/version'

module SQ
  class << self
    def user_agent
      "SQ/#{version} +github.com/bfontaine/sq"
    end

    def query(uri, regex=/./)
      uri = 'http://' + uri unless uri =~ /^https?:\/\//

      doc = Nokogiri::HTML(open(uri, 'User-Agent' => user_agent))
      links = doc.css('a[href]')

      uris = links.map { |a| URI.join(uri, a.attr('href')) }
      uris.select! { |u| u.path =~ /\.pdf$/i && u.to_s =~ regex }

      uris.map do |u|
        {
          :uri => u.to_s,
          :name => u.path.split('/').last
        }
      end
    end

    def process(uri, regex=/./, opts={})
      uris = self.query(uri, regex)

      puts "Found #{uris.count} PDFs." if opts[:verbose]

      return 0 if uris.empty?

      out = File.expand_path(opts[:directory] || '.')

      unless Dir.exists?(out)
        puts "-> mkdir #{out}" if opts[:verbose]
        Dir.mkdir(out)
      end

      uris.each do |u|
        puts "Downloading #{u[:name]}..." if opts[:verbose]
        open("#{out}/#{u[:name]}", 'wb') do |f|
          open(u[:uri], 'rb') do |resp|
            f.write(resp.read)
          end
        end
      end
    end
  end
end
