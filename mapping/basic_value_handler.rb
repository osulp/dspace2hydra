module Mapping
  module BasicValueHandler
    def unprocessed(value)
      value
    end

    def prepend(value, *args)
      "#{args.join(',')} #{value}"
    end
  end
end