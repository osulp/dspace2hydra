module Metadata
  module ClassMethodRunner
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
      if method.is_a? Array
        values << method.drop(1).map { |x| x }
      end
      klass.send(class_method.last, *values)
    end
  end
end