# frozen_string_literal: true
module Mapping
  class AdminSet
    require 'csv'
    require 'yaml'

    extend Extensions::BasicValueHandler

    ##
    # Locate adminset with the passing owning_collection handle
    #
    # @param[String] value - handle of owning collection
    # @param[Array] *args - properties passed to the method
    # return - adminset_id, a blank adminset_id maps to 'Default' adminset in Hyrax
    def self.lookup_admin_set(value, *_args)
      csv_file = File.join(File.dirname(__FILE__), '../lookup/collectionlist.csv')
      lines = CSV.read(csv_file, headers: true, encoding: 'UTF-8').map(&:to_hash)
      line = lines.find { |l| l['collection_handle'].casecmp(value).zero? }
      raise StandardError, "did not find collection_handle '#{value}' in collectionlist.csv" if line.nil? || line['Admin_Set_ID'].to_s.empty?
      line['Admin_Set_ID']
    end
  end
end
