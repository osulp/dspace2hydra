module Mapping
  module Extensions
    module BasicValueHandler
      ##
      # This mapped value is to be ignored and not included in the migration
      # @parameter [String] value - the value
      # @returns [Nil] - a nil
      def ignored(_value)
        nil
      end

      ##
      # The mapped value is passed through with no modification or mapping
      # @parameter [String] value - the value
      # @returns [String] - the value with leading and trailing whitespace stripped
      def unprocessed(value)
        value.strip! if value.is_a? String
        value
      end

      ##
      # This mapped value is returned with some text prepended to it
      # @parameter [String] value - the value
      # @parameter [*String] args - a variable number of string arguments
      # @returns [String] - the value with text from the args prepended to it
      def prepend(value, *args)
        "#{args.join(',')} #{unprocessed(value)}"
      end
    end
  end
end
