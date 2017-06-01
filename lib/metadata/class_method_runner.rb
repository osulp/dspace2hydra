# frozen_string_literal: true
module Metadata
  module ClassMethodRunner
    @logger = Logging.logger[self]
    @config = {}
    @field = ''

    ##
    # From an API perspective, this is the only public method intended to be called.
    # Process 'run_method' and add value(s) to data hash
    # @param [Hash] data - the data hash to add processed values to
    # @return [Hash] - the data hash with the new node/values injected
    def process_node(data = {})
      # run_method may return a String, Array<String>, or an Array<Hash>
      result = run_method

      # a nil result from a method indicates that the value should not be mapped/migrated
      @logger.warn("#{method} returned nil, unable to map metadata.") if result.nil?
      return data if result.nil?
      update_data(result, field_name, data)
    end

    private

    def method
      log_and_raise "#{@field} : missing 'method' configuration" if @config['method'].to_s.empty?
      @config['method']
    end

    def field_name
      log_and_raise "#{@field} : missing 'field.name' configuration" if field['name'].to_s.empty?
      field['name']
    end

    ##
    # Default, will be overridden by Node, CustomNode, or Qualifier
    def value_add_to_migration
      'always'
    end

    def value
      value_from_node_property.empty? ? @config['value'] : send(value_from_node_property.to_sym)
    end

    def field
      log_and_raise "#{@field} : missing 'field' configuration" if @config['field'].to_s.empty?
      @config['field']
    end

    def field_array?
      field_type.casecmp('array').zero?
    end

    def field_type
      log_and_raise "#{@field} : missing 'field.type' configuration" if field['type'].to_s.empty?
      field['type']
    end

    def field_property
      log_and_raise "#{@field} : missing 'field.property' configuration" if field['property'].to_s.empty?
      field['property']
    end

    def field_property_name(name)
      format(field_property, work_type: @work_type, field_name: name)
    end

    ##
    # Default, will be overridden by Node, CustomNode, or Qualifier
    def value_from_node_property
      ''
    end

    ##
    # Given the value from this, run the method configured for the qualifier if it exists otherwise the default
    # @return [String] - the result of the configured method should be a string to store in hydra
    def run_method
      send_method(method, value)
    end

    ##
    # Methods can return String, Array<String>, or Hash<:field_name,:value>.
    #
    # Add the result from the configured method to the data hash of arrays
    # given the field name configured or field_name provided by the result of the
    # configured method.
    # @param [String, Array<String>, Hash<:field_name,:value>] result - the result of the configured method
    # @param [String] field_name - the field_name configured for this node
    # @param [Hash] data - the data hash of the processed Metadata
    # @return [Hash] - the updated data hash
    def update_data(result, field_name, data)
      result = [result] unless result.is_a? Array
      # run_method returns an array of hashes or strings
      # when the array returns hashes, it expects the shape to be { field_name: '', value: ''}
      # when the array returns strings, add each to the array of the field_name configured for the node
      result.each do |r|
        value = r
        name = field_name
        if r.is_a?(Hash) && r.key?(:field_name) && r.key?(:value)
          name = r[:field_name]
          value = r[:value]
        end
        fields = field_property_name(name).split('.')
        data = set_deep_field_property(data, value, *fields)
      end
      data
    end

    ##
    # Set the value of a data_field after initializing it as an array if appropriate
    # @param [String] field_name - the data field name
    # @param [Hash] data - the data hash
    # @param [String|Integer] value - the value being considered for migration
    # @return [Array|String] - the data_field containing the value if appropriate
    def set_value(field_name, data, value)
      data_field = data[field_name]
      value = get_value(field_name, data, value)
      if field_array?
        data_field ||= []
        if value_add_to_migration.casecmp('overwrite_existing').zero?
          @logger.warn("#{method} found '#{field_name}' with 'overwrite_existing' configuration, setting value to '#{value}'")
          data_field = []
        end
        data_field << value unless value.nil? || data_field.any? { |v| v == value }
      else
        data_field = value unless value.nil?
      end
      data_field
    end

    ##
    # Evaluate the value_add_to_migration configuration to determine if the
    # value provided should be included in migration.
    # @param [String] field_name - the data field name
    # @param [Hash] data - the data hash
    # @param [String|Integer] value - the value being considered for migration
    # @return [String|Integer|nil] - the value, or nil, depending on the evaluation expressed by the configuration and existing migrated data
    def get_value(field_name, data, value)
      case value_add_to_migration.downcase
      when 'always'
        # noop
      when 'except_empty_value'
        if value.to_s.empty?
          @logger.warn("Configuration ('except_empty_value') set for '#{field_name}', will not map an empty value")
          value = nil
        end
      when 'if_form_field_value_missing'
        if data[field_name].nil? || data[field_name].empty?
          @logger.warn("Configuration ('if_form_field_value_missing') set for '#{field_name}' found empty value, applying '#{value}' from configuration")
        else
          value = nil
        end
      when 'never'
        @logger.warn("Configuration ('never') explicitly set for '#{field_name}', ignore metadata mapping")
        value = nil
      end
      value
    end

    ##
    # Traverse the supplied fields to create an arbitrarily deep nested
    # hash and inject the value at the final leaf.
    # Used in conjunction with a configuration like
    # field:
    #   name: some_field_name
    #   property: "%{work_type}.some.deep.%{field_name}"
    #   type: Array
    # @param [Hash] data - the data hash that is being built through processing metadata and custom nodes
    # @param [String|Integer] value - the value being considered to inject into data
    # @param [Array] fields - field.property configuration split on dots
    # @return [Hash] - the data with appropriate nested hashes and value injected
    def set_deep_field_property(data, value, *fields)
      if fields.count == 1
        data[fields[0]] = set_value(fields[0], data, value)
      else
        field = fields.shift
        data[field] = {} unless data[field]
        set_deep_field_property(data[field], value, *fields)
      end
      data
    end

    ##
    # Call a class method passing in an array of values, with the method expecting the first argument to be the value passed
    # into this 'send' method followed by a variable number of additional arguments. The idea here is that the configuration
    # could include some specific values to provide to the target method to aid in processing.
    # @param [String|Array] method - the full class method and optional arguments
    #                               (String: SomeClass.the_method_name)
    #                               (Array: ['SomeClass.the_method_name', 'argument1', 'arg2'])
    # @param [String] value - the initial value to operate upon, with additional arguments appended to the list
    # @return [String] - the returned processed value
    def send_method(method, value)
      values = [value]
      class_method = method.first.split('.') if method.is_a?(Array)
      class_method = method.split('.') if method.is_a?(String)
      klass = Object.const_get(class_method.first)
      values << method.drop(1).map { |x| x } if method.is_a? Array
      klass.send(class_method.last, *values)
    end
  end
end
