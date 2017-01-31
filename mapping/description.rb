module Mapping
  class Description
    extend BasicValueHandler

    def set_embargo(value, *args)
      field_name_one, field_name_two = args.flatten
      [
        { field_name: field_name_one, value: 'embargo' },
        { field_name: field_name_two, value: value }
      ]
    end
  end
end