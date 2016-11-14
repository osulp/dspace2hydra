module Metadata
  class Node
    attr_reader :config, :field, :qualifier, :xml_node

    def initialize(xml_node, field, config = {})
      @config = config
      @field = field
      @xml_node = xml_node
      @qualifier = build_qualifier
    end

    def content
      @xml_node.content
    end

    def form_field
      @qualifier.form_field
    end

    def xpath
      @config['xpath']
    end

    private

    ##
    # Determine if the xml_node has a qualifier attribute, and grab its value otherwise fallback on 'default',
    # then find the appropriate configuration block to initialize a Metadata::Qualifier for mapping/looking/etc on this node
    def build_qualifier
      @config["qualifiers"] ||= {}
      raise StandardError.new("#{@name} metadata configuration missing qualifiers.") if @config['qualifiers'].keys.empty?

      type = @xml_node.attributes.has_key?("qualifier") ? @xml_node.attributes["qualifier"].value : "default"
      config = @config["qualifiers"].select { |k,v| k == type }
      Metadata::Qualifier.new(type, config)
    end
  end
end