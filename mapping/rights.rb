# frozen_string_literal: true
module Mapping
  class Rights
    extend Extensions::BasicValueHandler

    ##
    # Process right_statement based on values in date_issued and right.uri
    # @param[Hash<String,<Array<Metadata::Node>>] value - The full hash of migration metadata with node name as the key and Metadata::Node array
    # @param[Array] *args - ignored

    # When custom_node overwrites migration_node (the same field_name), make sure the field types of qualifiers are the same (e.g., String or Array)
    # default qualifier method can overwrite node method
    def self.process_metadata(value, *_args)
      date_issued_node = value['date'].find { |n| n.qualifier.field_name.casecmp('date_issued').zero? }
      date_issued = date_issued_node.qualifier.run_method
      # journal article most likely has issued date at year month
      date_issued << '-01' if date_issued =~ /^\d{4}\-\d{2}$/
      date_issued << '-01-01' if date_issued =~ /^\d{4}$/

      rights_uri_node = value['rights'].find { |n| n.qualifier.field_name.casecmp('license').zero? }
      # rights statement is required and the code below assigns one even it is empty in DSpace
      if rights_uri_node.nil? && DateTime.parse(date_issued) > DateTime.new(1923, 12, 31)
        return 'http://rightsstatements.org/vocab/CNE/1.0/'
      elsif rights_uri_node.nil? && DateTime.parse(date_issued) <= DateTime.new(1923, 12, 31)
        return 'http://rightsstatements.org/vocab/NoC-US/1.0/'
      end
      rights_uri = rights_uri_node.qualifier.run_method

      # process rights_statement
      # https://docs.google.com/spreadsheets/d/1_Mj90z_abGrmn_xz-fnM8mF_NWGDv9br7kNIs6FfQWw/edit#gid=0

      # return rights_statement as public domain if published before 1923
      if DateTime.parse(date_issued) <= DateTime.new(1923, 12, 31)
        return 'http://rightsstatements.org/vocab/NoC-US/1.0/'
      # return public domain if license in DSpace is CC0
      elsif rights_uri.include? 'creativecommons.org/publicdomain/zero/1.0/'
        return 'http://rightsstatements.org/vocab/NoC-US/1.0/'
      # return in copyright if published after 1923 and license in DSpace is not empty
      elsif DateTime.parse(date_issued) > DateTime.new(1923, 12, 31) && rights_uri.include?('creativecommons.org/licenses')
        return 'http://rightsstatements.org/vocab/InC/1.0/'
      # return copyright not evaluated if published after 1923 and no license in DSpace
      elsif DateTime.parse(date_issued) > DateTime.new(1923, 12, 31) && rights_uri.empty?
        return 'http://rightsstatements.org/vocab/CNE/1.0/'
      # return in copyright if published 1923 and license in DSpace is all rights reserved
      elsif DateTime.parse(date_issued) > DateTime.new(1923, 12, 31) && rights_uri.include?('http://www.europeana.eu/portal/rights/rr-r.html')
        return 'http://rightsstatements.org/vocab/InC/1.0/'
      end
    end
  end
end
