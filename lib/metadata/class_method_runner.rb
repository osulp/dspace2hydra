module Metadata
  module ClassMethodRunner
    ##
    # From an API perspective, this is the only public method intended to be called.
    # Process 'run_method' and add value(s) to data hash
    # @param [Hash] data - the data hash to add processed values to
    # @return [Hash] - the data hash with the new node/values injected
    def process_node(data = {})
      # run_method may return a String, Array<String>, or an Array<Hash>
      result = run_method

      # a nil result from a method indicates that the value should not be mapped/migrated
      return data if result.nil?
      update_data(result, data)
    end

    private

    def method
      @config['method']
    end

    def has_method?
      !method.nil?
    end

    def content
      @config['value']
    end

    def field_name
      form_field(@config['form_field_name'])
    end

    ##
    # Given the value from this, run the method configured for the qualifier if it exists otherwise the default
    # @return [String] - the result of the configured method should be a string to store in hydra
    def run_method
      raise StandardError.new("#{field} run_method is missing method configuration") unless has_method?
      send(method, content)
    end

    ##
    # Methods can return String, Array<String>, or Hash<:field_name,:value>.
    #
    # Add the result from the configured method to the data hash of arrays
    # given the field name configured or field_name provided by the result of the
    # configured method.
    # @param [String, Array<String>, Hash<:field_name,:value>] result - the result of the configured method
    # @param [Hash] data - the data hash of the processed Metadata
    # @return [Hash] - the updated data hash
    def update_data(result, data)
      if result.is_a?(String) || result.is_a?(Fixnum)
        # ensure the form_field is set in the hash and add the processed value to it
        data[field_name] ||= []
        data[field_name] << result
      else
        # run_method returns an array of hashes or strings
        # when the array returns hashes, it expects the shape to be { field_name: '', value: ''}
        # when the array returns strings, add each to the array of the field_name configured for the node
        result.each do |r|
          if r.is_a?(Hash)
            data[form_field(r[:field_name])] ||= []
            data[form_field(r[:field_name])] << r[:value].to_s
          else
            data[field_name] ||= []
            data[field_name] << r.to_s
          end
        end
      end
      data
    end

    ##
    # Call a class method passing in an array of values, with the method expecting the first argument to be the value passed
    # into this 'send' method followed by a variable number of additional arguments. The idea here is that the configuration
    # could include some specific values to provide to the target method to aid in processing.
    # @param [String|Array] method - the full class method and optional arguments
    #                               (String: SomeClass.the_method_name)
    #                               (Array: ['SomeClass.the_method_name', 'argument1', 'arg2')
    # @param [String] value - the initial value to operate upon, with additional arguments appended to the list
    # @return [String] - the returned processed value
    def send(method, value)
      values = [value]
      class_method = method.first.split('.') if method.is_a?(Array)
      class_method = method.split('.') if method.is_a?(String)
      klass = Object.const_get(class_method.first)
      values << method.drop(1).map { |x| x } if method.is_a? Array
      klass.send(class_method.last, *values)
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
      sprintf(@config['form_field'], work_type: @work_type, form_field_name: form_field_name)
    end
  end
end
