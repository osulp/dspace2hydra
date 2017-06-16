# frozen_string_literal: true
module Mapping
  class License
    extend Extensions::BasicValueHandler

    ##
    # Process license based on values in date_issued and right.uri
    # @param[Hash<String,<Array<Metadata::Node>>] value - The full hash of migration metadata with node name as the key and Metadata::Node array
    # @param[Array] *args - ignored

    # When custom_node overwrites migration_node (the same field_name), make sure the field types of qualifiers are the same (e.g., String or Array)
    # default qualifier method can overwrite node method
    def self.process_metadata(value, *_args)
      date_issued_node = value['date'].find { |n| n.qualifier.field_name.casecmp('date_issued').zero? }
      date_issued = date_issued_node.qualifier.run_method
      rights_uri_node = value['rights'].find { |n| n.qualifier.field_name.casecmp('license').zero? }
      # return nil for license if there is no input from DSpace
      return nil if rights_uri_node.nil?
      rights_uri = rights_uri_node.qualifier.run_method

      # process license
      # https://docs.google.com/spreadsheets/d/1_Mj90z_abGrmn_xz-fnM8mF_NWGDv9br7kNIs6FfQWw/edit#gid=0

      # return public domain as-is
      return rights_uri if rights_uri.downcase.include?('http://creativecommons.org/publicdomain/zero/1.0/')

      # journal article most likely has issued date at year month
      date_issued << '-01' if date_issued =~ /^\d{4}\-\d{2}$/
      raise StandardError, "The value of date_issued only have year, the system expects at least year, month in YYYY-MM format." if date_issued =~ /^\d{4}$/
      
      # anything after 1923, with creativecommons return the rights_uri
      if DateTime.parse(date_issued) > DateTime.new(1923, 12, 31) && rights_uri.include?('creativecommons.org')
        return rights_uri
      else
        return nil
      end
    end
  end
end
