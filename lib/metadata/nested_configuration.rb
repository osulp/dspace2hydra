# frozen_string_literal: true
module Metadata
  module NestedConfiguration
    ##
    # Given a key name for a configuration, find the first hash containing the configuration.
    # This method implies that the hashes passed to it have some priority in the sequence
    # in which they are supplied. This effectively provides a way for the first hash to 'override'
    # the configuration provided by the second hash.
    # @param [String|Symbol] key - the configuration key to find
    # @param [Hash] hashes - a number of supplied hashes containing the configuration
    # @return [Object] - the value of the first configuration found with key
    def get_configuration(key, *hashes)
      config = hashes.find { |h| !h[key].nil? }
      raise StandardError, "default configuration for '#{key}' not found in any supplied configurations" if config.nil?
      config[key]
    end
  end
end
