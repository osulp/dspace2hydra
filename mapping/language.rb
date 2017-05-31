# frozen_string_literal: true
require 'iso-639'

module Mapping
  class Language
    extend Extensions::BasicValueHandler
    extend Extensions::Cacheable

    LOC_LANGUAGES_CACHE_FILE = 'loc.languages.yml'
    LOC_ISO639_2_URI = 'http://id.loc.gov/vocabulary/iso639-2/%{alpha3_code}'

    ##
    # Get the uri from ISO-639 gem
    # @param [String] value - the language text to find a URI for
    # @param [Array] *args - a variable number of arguments provided. None needed for this method
    # @return [String] - the URI for the language provided
    def self.uri(value, *_args)
      item = search_cache(value, :value, LOC_LANGUAGES_CACHE_FILE)
      return item[:uri].to_s if item

      entry = find_language(value)
      raise StandardError, "Could not find #{value} in ISO 639-2." unless entry

      item = Extensions::Cacheable::Item.new(value, value, entry.english_name, format(LOC_ISO639_2_URI, alpha3_code: entry.alpha3))
      add_to_cache(item, LOC_LANGUAGES_CACHE_FILE)
      item[:uri].to_s
    end

    private

    ##
    # Find the language entry related to the value provided.
    # @param [String] s - the value to be parsed
    # @return [Array] - the ISO_639 language entry or nil if none found
    def self.find_language(s)
      s.strip!
      entry = ISO_639.find_by_code(s) if s.length == 2
      entry = parse_code(s) if entry.nil?
      entry = parse_language(s) if entry.nil?
      entry
    end

    ##
    # Find the language for a given alpha2 code, parsed from the value provided.
    # @example 'en_US'
    # @param [String] s - the value to be parsed
    # @return [Array] - the ISO_639 language entry
    def self.parse_code(s)
      match_data = /^(\w+)(_\w+)$/.match(s)
      ISO_639.find_by_code(match_data[1]) if match_data.to_a.size > 1
    end

    ##
    # Find the language for a given english name language, parsed from the value provided.
    # @example 'English (United States)'
    # @param [String] s - the value to be parsed
    # @return [Array] - the ISO_639 language entry
    def self.parse_language(s)
      match_data = /^(\w+)\s+(.*)$/.match(s)
      ISO_639.find_by_english_name(match_data[1]) if match_data.to_a.size > 1
    end
  end
end
