require 'rdf'

module Mapping
  class Subject
    extend Extensions::BasicValueHandler
    extend Extensions::LocSearchable
    extend Extensions::Cacheable
    include RDF

    LCSH_CONTENT_SOURCE = "http://id.loc.gov/authorities/subjects"
    LCSH_CACHE_FILE = "loc.subjects.yml"

    ##
    # Get the uri from LOC for the subject text provided
    # @param [String] value - the LCSH text to find a URI for
    # @param [Array] *args - a variable number of arguments provided. None needed for this method
    # @return [String] - the URI for the LCSH provided
    def self.uri(value, *args)
      item = self.search_cache(value, LCSH_CACHE_FILE)
      return item[:uri].to_s unless item.nil?

      item = self.search_loc(LCSH_CONTENT_SOURCE, value)
      raise StandardError.new("Could not find #{value} in LCSH.") if item.nil?
      self.add_to_cache(item, LCSH_CACHE_FILE)
      item[:uri].to_s
    end
  end
end
