# frozen_string_literal: true
module Mapping
  module Extensions
    module Cacheable
      Item = Struct.new(:id, :value, :label, :uri)
      CACHED_CLASSES = [Item, Symbol].freeze
      CACHE_DIRECTORY = '../../../cache'

      ##
      # Search the yaml cache for a record with a `label` matching the supplied string
      # @param [String] str - the string to search for
      # @param [Symbol] field - the item field containing the string to find
      # @param [String] filename - the filename in the cache directory to search
      # @param [Array<Class>] cached_classes - additional classes to allow for caching
      # @return [Hash|nil] - the item that was found or nil if not found
      def search_cache(str, field, filename, cached_classes = [])
        # check the cache for the "label", return it or empty
        File.open(File.join(File.dirname(__FILE__), CACHE_DIRECTORY, filename), 'a+') do |file|
          items = YAML.safe_load(file, CACHED_CLASSES + cached_classes)
          return items.find { |item| item[field] == str } if items
        end
      end

      ##
      # Add an item to the cache
      # @param [Hash] item - the item to add to the cache
      # @param [String] filename - the filename in the cache directory to append the item to
      # @return [Hash] - the item that was appended to the cache
      def add_to_cache(item, filename)
        # open and add this value to the cache
        File.open(File.join(File.dirname(__FILE__), CACHE_DIRECTORY, filename), 'a+') do |file|
          # want to append valid YAML to the end of the document, but without the standard YAML document separator
          # because we are building a YAML document dynamically, and don't want to read and parse the entire thing just
          # to add another element to the list.. not really proud, this seems hackish, but `to_yaml` doesn't provide an
          # option otherwise
          file.write([item].to_yaml.slice(3...-1))
        end
        item
      end
    end
  end
end
