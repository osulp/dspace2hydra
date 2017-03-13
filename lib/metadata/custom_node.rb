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

    def value_add_to_migration
      get_configuration 'value_add_to_migration', @config, @work_type_config
    end
  end
end
