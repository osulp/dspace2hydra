# frozen_string_literal: true
module Mapping
  class Type
    extend Extensions::BasicValueHandler

    ##
    # Use the resource.types.yml to map the original Dspace value to a resource type in Hyrax
    # @param [String] value - the original Dspace value for the node
    # @param [*String] args - the field name to map values to
    # @return [[Hash]] - the field in hydra with the new value

    def self.lookup_hyrax_type(value, *args)
      lookup = File.open(File.join(File.dirname(__FILE__), '../lookup/resource.types.yml')) { |f| YAML.safe_load(f) }
      resource_type_map = lookup.find { |l| l['from'].casecmp(value).zero? }
      field_name = args.flatten.first
      { field_name: field_name, value: resource_type_map['to'] }
    end
  end
end
