# frozen_string_literal: true
module Metadata
  class CustomNode
    include ClassMethodRunner
    include NestedConfiguration
    attr_reader :config

    def initialize(work_type_config, config = {})
      @config = config
      @work_type_config = work_type_config
      @work_type = work_type_config['work_type']
    end

    def admin_set_id
      get_configuration 'admin_set_id', @config, @work_type_config
    end

    def value_add_to_migration
      get_configuration 'value_add_to_migration', @config, @work_type_config
    end

    def value_from_node_property
      get_configuration 'value_from_node_property', @config, @work_type_config
    end
  end
end
