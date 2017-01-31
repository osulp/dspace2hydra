module Mapping
  class Description
    extend BasicValueHandler

    ##
    # Set the visiblity to "embargo" and the embargo release date to the value from Dspace
    # @param [String] value - the original Dspace value for the node
    # @param [Array] *args - the two field names to map values to
    # @return [Array[Hash]] - the two fields in hydra with the new values
    def set_embargo(value, *args)
      field_name_one, field_name_two = args.flatten
      [
        { field_name: field_name_one, value: 'embargo' },
        { field_name: field_name_two, value: value }
      ]
    end

    ##
    # Use the embargopolicy yml to map the original Dspace value to a new value, and set the second field value to 'open access'
    # The first field is intended to be the embargo policy when the item was "in embargo" and the second field is "after embargo"
    # @param [String] value - the original Dspace value for the node
    # @param [Array] *args - the two field names to map values to
    # @return [Array[Hash]] - the two fields in hydra with the new values
    def lookup_embargo_policy(value, *args)
      field_name_one, field_name_two = args.flatten
      lookup = File.open(File.join(File.dirname(__FILE__), '../lookup/description.embargopolicy.yml')) { |f| YAML.load(f) }
      embargo_map = lookup.select { |l| l[:from] == value }
      [
        { field_name: field_name_one, value: embargo_map[:to] },
        { field_name: field_name_two, value: 'open access' },
      ]
    end
  end
end