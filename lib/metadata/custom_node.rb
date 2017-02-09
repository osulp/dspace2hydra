module Metadata
  class CustomNode
    include ClassMethodRunner
    attr_reader :config

    def initialize(work_type, config = {})
      @config = config
      @work_type = work_type
    end
  end
end
