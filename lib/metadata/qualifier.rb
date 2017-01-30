module Metadata
  class Qualifier
    include ClassMethodRunner
    attr_reader :config, :type

    def initialize(field, type, config)
      @field = field
      @type = type
      @config = config
    end

    def default?
      @type == 'default'
    end

    def form_field_name
      @config[@type]['form_field_name']
    end

    def method
      @config[@type]['method']
    end

    def has_method?
      !method.nil?
    end

    ##
    # Given the value from the Metadata::Node, run the method configured for the qualifier
    # @param [String] value - the Metadata::Node value/content
    # @return [String] the result of the configured method should be a string to store in hydra
    def run_method(value)
      raise StandardError.new("#{@field}.#{@type} run_method is missing method configuration.") unless has_method?
      send(method, value)
    end
  end
end