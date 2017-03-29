# frozen_string_literal: true
require 'rdf'
require_relative '../lib/loggable'

module Mapping
  ##
  # LCSH Subject
  class Subject
    include Loggable
    @logger = Logging.logger[self]

    extend Extensions::BasicValueHandler
    extend Extensions::LocSearchable
    extend Extensions::Cacheable
    include RDF

    LCSH_CONTENT_SOURCE = 'http://id.loc.gov/authorities/subjects'
    LCSH_CACHE_FILE = 'loc.subjects.yml'

    ##
    # Get the uri from LOC for the subject text provided
    # @param [String] value - the LCSH text to find a URI for
    # @param [Array] *args - a variable number of arguments provided. None needed for this method
    # @return [String] - the URI for the LCSH provided
    def self.uri(value, *_args)
      item = search_cache(value, :label, LCSH_CACHE_FILE, [RDF::URI])
      @logger.info("Subject.uri found '#{value}' cached with #{item[:uri]}") if item
      return item[:uri].to_s if item

      found = search_loc(LCSH_CONTENT_SOURCE, value)
      item = Extensions::Cacheable::Item.new(found[:id], found[:id], found[:label], found[:uri])
      raise StandardError, "Could not find #{value} in LCSH." unless item
      add_to_cache(item, LCSH_CACHE_FILE)
      # TODO : see issue #79 for how this should be handled
      item[:uri].to_s
    end
  end
end
