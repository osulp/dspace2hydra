module Metadata
  class Qualifier
    attr_reader :config, :type

    def initialize(type, config)
      @type = type
      @config = config
    end

    def default?
      @type == 'default'
    end

    def form_field
      @config[@type]['form_field']
    end
  end
end