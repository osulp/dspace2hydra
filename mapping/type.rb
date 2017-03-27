module Mapping
  class Type
    extend Extensions::BasicValueHandler

    ##
    # Use the resource.types.yml to map the original Dspace value to a resource type in Hyrax
    # @param [String] value - the original Dspace value for the node
    # @param [*String] args - the field name to map values to
    # @return [[Hash]] - the field in hydra with the new value

    def lookup_hyrax_type(value, *args)
      lookup = File.open(File.join(File.dirname(__FILE__), '../lookup/resource.types.yml')) { |f| YAML.load(f) }
      resource_type_map = lookup.select { |l| l[:from] == value }
      return [ {  field_name: args, value: resource_type_map[:to]} ]
    end
  end
end
