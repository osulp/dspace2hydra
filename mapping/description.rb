module Mapping
  class Description
    extend Extensions::BasicValueHandler

    ##
    # Set the visiblity to "embargo" and the embargo release date to the value from Dspace
    # @param [String] value - the original Dspace value for the node
    # @param [Array] *args - the three field names to map values to
    # @return [Array[Hash]] - the three fields in hydra with the new values
    def self.set_embargo(value, *args)
      field_name_one, field_name_two, field_name_three = args.flatten
      [
        { field_name: field_name_one, value: 'embargo' },
        { field_name: field_name_two, value: value },
        { field_name: field_name_three, value: 'Existing Confidentiality Agreement'}
      ]
    end

    ##
    # Use the embargopolicy yml to map the original Dspace value to a new value, and set the second field value to 'open access'
    # The first field is intended to be the embargo policy when the item was "in embargo" and the second field is "after embargo"
    # @param [String] value - the original Dspace value for the node
    # @param [Array] *args - the two field names to map values to
    # @return [Array[Hash]] - the two fields in hydra with the new values
    def self.lookup_embargo_policy(value, *args)
      field_name_one, field_name_two = args.flatten
      lookup = File.open(File.join(File.dirname(__FILE__), '../lookup/description.embargopolicy.yml')) { |f| YAML.safe_load(f) }
      embargo_map = lookup.find { |l| l['from'].casecmp(value).zero? }
      [
        { field_name: field_name_one, value: embargo_map['to'] },
        { field_name: field_name_two, value: 'open access' },
      ]
    end

    ##
    # Process the description from the original Dspace value to graduation_year if it matches 'Graduation date:'
    # The first field is gradution_year if pattern matches and the second field is description by default
    # @param [String] value - the original Dspace value for the node
    # @param [Array] *args - the two field names to map value to
    # @return [[Hash]] - the field in hydra with the new value
    def self.process_if_grad_date(value, *args)
      field_name_one, field_name_two = args.flatten
      match_data = /^graduation date:/.match(value.downcase)
      if match_data.nil?
        # not found, unprocessed
        return [ { field_name: field_name_two, value: value } ]
      else
        # found "graduation date"
        return [ { field_name: field_name_one, value: value.split(':')[1].strip } ]
      end
    end

    ##
    # Translate the DSpace 'yes', 'no' or other related values to 'TRUE', or 'FALSE'
    # to match the servers local vocabulary for this field.
    # @param [String] value - the original Dspace value for the node
    # @return [String] - the 'TRUE' or 'FALSE' for this field
    def self.translate_peerreviewed(value, *args)
      %w(1 true yes y).include?(value.to_s.downcase).to_s.upcase
    end
  end
end
