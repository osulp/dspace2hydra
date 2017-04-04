# frozen_string_literal: true
require 'json'
require 'mechanize'
require 'mechanize/util'

module Mapping
  module Extensions
    module LocSearchable
      LCSH_SEARCH_BASE_URL = 'http://id.loc.gov/search/'

      ##
      # Query LOC search to find a list of items matching the query
      # @param [String] content_source - the LOC authority to search within for the supplied query string
      # @param [String] str - the query string to search for
      # @return [Hash] - an item shaped as {id,label,uri}
      def search_loc(content_source, str)
        url = "#{LCSH_SEARCH_BASE_URL}?q=#{Mechanize::Util.uri_escape(str)}&q=#{content_source}&format=json"
        @logger.info("Searching LCSH #{url}")
        response = Mechanize.new.get(url)

        items = parse_items(response.body)

        unless items.empty?
          found = items.find { |i| i[:label].casecmp(str.downcase.strip).zero? }
          unless found.nil?
            uri = RDF::URI(found[:id].gsub('info:lc', 'http://id.loc.gov'))
            @logger.info("Found #{uri}")
            return found.merge(uri: uri)
          end
          @logger.warn("#{items.count} returned, but none matching '#{str}'")
        end
        @logger.warn('No items parsed in return from LCSH search query')
        # TODO : see issue #79 for how this should be handled
        { id: str, label: str, uri: str }
      end

      ##
      # Parse the JSON formatted atom entries to return simple ID and LABEL objects
      # @param [String] str - a JSON encoded string
      # @return [Hash] - an item shaped as {id,label
      def parse_items(str)
        json = JSON.parse(str)
        json.select { |node| node.is_a?(Array) && node[0] == 'atom:entry' }.map do |entry|
          id = entry.find { |node| node.is_a?(Array) && node[0] == 'atom:id' }[2]
          title = entry.find { |node| node.is_a?(Array) && node[0] == 'atom:title' }[2]
          { id: id || title, label: title }
        end
      end
    end
  end
end
