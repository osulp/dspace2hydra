module Mapping
  class Degree
    extend BasicValueHandler

    ##
    # Split the Degree value and remap values to new field names,
    # for instance "Doctor of Philosophy (Ph. D.) in Animal Husbandry" would result
    # in the field_name's provided with a value of "Doctor of Philosophy (Ph. D.)" and "Animal Husbandry"
    # @param [String] value - the original value to be split and remapped
    # @param [Array] *args - the configured field_names to pair with split values
    # @return [Array<Hash>] - the remapped split value
    def self.remapped_field_split(value, *args)
      field_name_one, field_name_two = args.flatten
      matches = value.match(/(.*\)) in (.*)/)
      [
        { field_name: field_name_one,  value: matches[1] },
        { field_name: field_name_two,  value: matches[2] }
      ]
    end
  end
end