# frozen_string_literal: true
module Mapping
  class Degree
    extend Extensions::BasicValueHandler

    DEGREE_NAMES_FILE = '../lookup/degree_names.yml'
    DEGREE_FIELDS_FILE = '../lookup/degree_fields.yml'

    ##
    # Split the Degree value and remap values to new field names,
    # for instance "Doctor of Philosophy (Ph. D.) in Animal Husbandry" would result
    # in the field_name's provided with a value of "Doctor of Philosophy (Ph. D.)" and "Animal Husbandry".
    # In the case of "Doctor of Philosophy (Ph. D.)", the result would just send back "Doctor of Philosophy (Ph. D.)"
    # in the first field name, ignoring the second field name due to not matching on the split.
    # @param [String] value - the original value to be split and remapped
    # @param [Array] *args - the configured field_names to pair with split values
    # @return [Array<Hash>] - the remapped split value
    def self.remapped_field_split(value, *args)
      field_name_one, field_name_two = args.flatten
      # matches when zero or more spaces around the spliter
      matches = value.match(/(.*\))\s*(in|n|iin|-n|i|min)*\s*(.*)/i)
      degree_name_value = matches ? matches[1] : value
      lookup = File.open(File.join(File.dirname(__FILE__), DEGREE_NAMES_FILE)) { |f| YAML.safe_load(f) }
      degree_name_map = lookup.find { |l| l['from'].casecmp(degree_name_value).zero? }
      degree_name = degree_name_map['to']
      fields = [ { field_name: field_name_one, value: degree_name } ]
      unless matches.nil? || matches[3].nil? || matches[3].empty?
        degree_field_value = matches[3]
        lookup_degree_field = File.open(File.join(File.dirname(__FILE__), DEGREE_FIELDS_FILE)) { |f| YAML.safe_load(f) 
        degree_field_map = lookup_degree_field.find { |l| l['from'].casecmp(degree_field_value).zero? } 
        degree_field_uri = degree_field_map['to']
        fields << { field_name: field_name_two, value: degree_field_uri }
      end
      fields
    end
  end
end
