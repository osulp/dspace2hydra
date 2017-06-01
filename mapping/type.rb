# frozen_string_literal: true
module Mapping
  class Type
    extend Extensions::BasicValueHandler

    include Loggable
    @logger = Logging.logger[self]

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

    def self.type_for_degree_level(metadata, *_args)
      # using the pre-processed metadata hash of nodes, grab the translated degree_level and resource_type
      # to reset the resource_type to the appropriate value depending on which degree_level the item
      # is set to.
      type_node = metadata['type'].find { |n| n.qualifier.field_name.casecmp('resource_type').zero? }
      type = type_node.qualifier.run_method
      type_value = type.is_a?(Hash) ? type[:value] : type

      degree_level_node = metadata['degree'].find { |n| n.qualifier.field_name.casecmp('degree_level').zero? }
      return type_value if degree_level_node.nil?

      degree_level = degree_level_node.qualifier.run_method
      degree_level.delete!("'")

      case type_value.downcase
      when 'thesis'
        return 'Dissertation' if degree_level.casecmp('doctoral').zero?
        return 'Masters Thesis' if degree_level.casecmp('masters').zero?
      else
        @logger.fatal("Mapping::type_for_degree_level expected 'thesis' but found '#{type_value}' in metadata.")
        return type_value
      end
    end
  end
end
