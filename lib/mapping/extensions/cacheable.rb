module Mapping
  module Extensions
    module Cacheable
      ##
      # Search the yaml cache for a record with a `label` matching the supplied string
      # @param [String] str - the string label to search for
      # @param [String] filename - the filename in the cache directory to search
      # @return [Hash|nil] - the item that was found or nil if not found
      def search_cache(str, filename)
        # check the cache for the "label", return it or empty
        File.open(File.join(File.dirname(__FILE__), "../../../cache", filename), 'a+') do |file|
          items = YAML.load(file)
          return items.find { |item| item[:label] == str } if items
        end
      end

      ##
      # Add an item to the cache
      # @param [Hash] item - the item to add to the cache
      # @param [String] filename - the filename in the cache directory to append the item to
      # @return [Hash] - the item that was appended to the cache
      def add_to_cache(item, filename)
        # open and add this value to the cache
        File.open(File.join(File.dirname(__FILE__), "../../../cache", filename), 'a+') do |file|
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
