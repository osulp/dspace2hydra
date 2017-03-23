# frozen_string_literal: true
module Metadata
  class Qualifier
    include ClassMethodRunner
    include NestedConfiguration
    attr_reader :config, :type

    def initialize(field, qualifier, work_type_config, node_config, value)
      @field = field
      @qualifier = qualifier
      @work_type_config = work_type_config
      @work_type = work_type_config['work_type']
      @node_config = node_config
      @config = node_config['qualifiers'][qualifier]
      @value = value
      raise StandardError, "#{field} metadata configuration missing '#{qualifier}' qualifier." if @config.nil?
    end

    def default?
      @qualifier == 'default'
    end

    def value_add_to_migration
      get_configuration 'value_add_to_migration', @config, @node_config, @work_type_config
    end

    def field_name
      get_configuration 'name', @config['field'], @node_config['field']
    end

    def field_property
      get_configuration 'property', @config['field'], @node_config['field']
    end

    def field_type
      get_configuration 'type', @config['field'], @node_config['field']
    end

    def method
      get_configuration 'method', @config, @node_config
    end

    ##
    # Given the value from the Metadata::Node, run the method configured for the qualifier
    # @param [String] value - the Metadata::Node value/content
    # @return [String] the result of the configured method should be a string to store in hydra
    def run_method
      raise StandardError, "#{@field}.#{@qualifier} run_method is missing method configuration." if method.nil?
      send_method(method, @value)
    end
  end
end
