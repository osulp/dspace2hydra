# frozen_string_literal: true
module Metadata
  class Node
    include ClassMethodRunner
    include NestedConfiguration
    attr_reader :config

    def initialize(xml_node, field, work_type_config, config = {})
      @config = config
      @field = field
      @work_type_config = work_type_config
      @work_type = work_type_config['work_type']
      @xml_node = xml_node
      @qualifier = build_qualifier
    end

    # Override methods from ClassMethodRunner so that this class behaves properly with regard
    # to its configuration or its Qualifier configuration.
    private

    ##
    # Given the value from this, run the method configured for the qualifier if it exists otherwise the default
    # @return [String] the result of the configured method should be a string to store in hydra
    def run_method
      @qualifier.run_method(value)
    end

    def value
      @xml_node.content
    end

    ##
    # Return the formatted form_field using the provided form_field_name or this nodes qualifiers configured form_field_name
    # Pertinent portion of example configuration:
    # description:
    #   form_field: "generic_work['%{form_field_name}'][]"
    #   qualifiers:
    #     default:
    #       form_field_name: some_field_name
    # @param String form_field_name - a provided string name for the form_field_name
    # @return String - the properly formatted form field name by this nodes configured "form_field" and
    #                   the provided form_field_name or the qualifiers configured "form_field_name"
    def form_field(form_field_name = nil)
      form_field_name ||= @qualifier.form_field_name
      format(@config['form_field'], work_type: @work_type, form_field_name: form_field_name)
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

      type = @xml_node.attributes.key?('qualifier') ? @xml_node.attributes['qualifier'].value : 'default'
      Metadata::Qualifier.new(@field, type, @work_type_config, @config)
    end
  end
end
