# frozen_string_literal: true
module Metadata
  class Qualifier
    include ClassMethodRunner
    include NestedConfiguration
    attr_reader :config, :type

    def initialize(field, type, work_type_config, node_config)
      @field = field
      @type = type
      @work_type_config = work_type_config
      @node_config = node_config
      @config = node_config['qualifiers'][type]
      raise StandardError, "#{field} metadata configuration missing '#{type}' qualifier." if @config.nil?
    end

    def default?
      @type == 'default'
    end

    def value_add_to_migration
      get_configuration 'value_add_to_migration', @config, @node_config, @work_type_config
    end

    def form_field_name
      get_configuration 'form_field_name', @config, @node_config
    end

    def method
      get_configuration 'method', @config, @node_config
    end

    ##
    # Given the value from the Metadata::Node, run the method configured for the qualifier
    # @param [String] value - the Metadata::Node value/content
    # @return [String] the result of the configured method should be a string to store in hydra
    def run_method(value)
      raise StandardError, "#{@field}.#{@type} run_method is missing method configuration." if method.nil?
      send(method, value)
    end
  end
end
