# frozen_string_literal: true
module Metadata
  class CustomNode
    include Loggable
    include ClassMethodRunner
    include NestedConfiguration
    attr_reader :config

    def initialize(item, field, work_type_config, config = {})
      @logger = Logging.logger[self]
      @config = config
      @config['field'] ||= {}
      @work_type_config = work_type_config
      @work_type = work_type_config['work_type']
      @item = item
      @field = field
    end

    def admin_set_id
      get_configuration 'admin_set_id', @config, @work_type_config
    rescue StandardError => e
      @logger.fatal("#{@field} : #{e.message}")
      raise e
    end

    def value_add_to_migration
      get_configuration 'value_add_to_migration', @config, @work_type_config
    rescue StandardError => e
      @logger.fatal("#{@field} : #{e.message}")
      raise e
    end

    def value_from_node_property
      get_configuration 'value_from_node_property', @config, @work_type_config
    rescue StandardError => e
      @logger.fatal("#{@field} : #{e.message}")
      raise e
    end

    def field_name
      get_configuration 'name', @config['field']
    rescue StandardError => e
      @logger.fatal("#{@field} : field.#{e.message}")
      raise e
    end

    def field_property
      get_configuration 'property', @config['field']
    rescue StandardError => e
      @logger.fatal("#{@field} : field.#{e.message}")
      raise e
    end

    def field_type
      get_configuration 'type', @config['field']
    rescue StandardError => e
      @logger.fatal("#{@field} : field.#{e.message}")
      raise e
    end

    def owner_id
      @item.owner_id
    end

    def collection_handles
      @item.collection_handles
    end
  end
end
