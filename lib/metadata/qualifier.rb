# frozen_string_literal: true
module Metadata
  class Qualifier
    include Loggable
    include ClassMethodRunner
    include NestedConfiguration
    attr_reader :config, :type

    def initialize(field, qualifier, work_type_config, node_config, value)
      @logger = Logging.logger[self]
      @field = field
      @qualifier = qualifier
      @work_type_config = work_type_config
      @work_type = work_type_config['work_type']
      @node_config = node_config
      @node_config['field'] ||= {}
      @config = node_config['qualifiers'][qualifier]
      @config['field'] ||= {}
      @value = value
    end

    def default?
      @qualifier == 'default'
    end

    def value_add_to_migration
      get_configuration 'value_add_to_migration', @config, @node_config, @work_type_config
    rescue StandardError => e
      @logger.fatal("#{@field}.#{@qualifier} : #{e.message}")
      raise e
    end

    def field_name
      get_configuration 'name', @config['field'], @node_config['field']
    rescue StandardError => e
      @logger.fatal("#{@field}.#{@qualifier} : field.#{e.message}")
      raise e
    end

    def field_property
      get_configuration 'property', @config['field'], @node_config['field']
    rescue StandardError => e
      @logger.fatal("#{@field}.#{@qualifier} : field.#{e.message}")
      raise e
    end

    def field_type
      get_configuration 'type', @config['field'], @node_config['field']
    rescue StandardError => e
      @logger.fatal("#{@field}.#{@qualifier} : field.#{e.message}")
      raise e
    end

    def method
      get_configuration 'method', @config, @node_config
    rescue StandardError => e
      @logger.fatal("#{@field}.#{@qualifier} : #{e.message}")
      raise e
    end

    ##
    # Given the value from the Metadata::Node, run the method configured for the qualifier
    # @param [String] value - the Metadata::Node value/content
    # @return [String] the result of the configured method should be a string to store in hydra
    def run_method
      send_method(method, @value)
    end
  end
end
