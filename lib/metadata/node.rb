module Metadata
  class Node
    include ClassMethodRunner
    attr_reader :config, :field, :qualifier, :xml_node

    def initialize(xml_node, field, config = {})
      @config = config
      @field = field
      @xml_node = xml_node
      @qualifier = build_qualifier
    end

    ##
    # Given the value from this, run the method configured for the qualifier if it exists otherwise the default
    # @return [String] the result of the configured method should be a string to store in hydra
    def run_method
      if @qualifier.has_method?
        @qualifier.run_method(content)
      else
        raise StandardError.new("#{field} run_method is missing method configuration") unless has_method?
        send(method, content)
      end
    end

    def method
      @config['method']
    end

    def has_method?
      !method.nil?
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
      config = @config["qualifiers"].select { |k, v| k == type }
      raise StandardError.new("#{@name} metadata configuration missing '#{type}' qualifier.") unless config[type]
      Metadata::Qualifier.new(field, type, config)
    end
  end
end
