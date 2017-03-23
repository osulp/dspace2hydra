# frozen_string_literal: true
module Metadata
  class Node
    attr_reader :config, :qualifier

    def initialize(xml_node, field, work_type_config, config = {})
      @config = config
      @field = field
      @work_type_config = work_type_config
      @work_type = work_type_config['work_type']
      @xml_node = xml_node
      @qualifier = build_qualifier
    end

    def value
      @xml_node.content
    end

    ##
    # Determine if the xml_node has a qualifier attribute, and grab its value otherwise fallback on 'default',
    # then find the appropriate configuration block to initialize a Metadata::Qualifier for mapping/looking/etc on this node
    # @config represents the YAML block of configuration for this specific node, for example 'description' nodes config:
    #
    # description:
    #   # Config hash
    #   xpath: ...
    #   method: ...
    #   qualifiers:
    #     default:
    #       ...
    def build_qualifier
      @config['qualifiers'] ||= {}
      raise StandardError, "#{@name} metadata configuration missing qualifiers." if @config['qualifiers'].keys.empty?

      qualifier = @xml_node.attributes.key?('qualifier') ? @xml_node.attributes['qualifier'].value : 'default'
      Metadata::Qualifier.new(@field, qualifier, @work_type_config, @config, value)
    end
  end
end
