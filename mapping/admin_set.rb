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
    def self.lookup_admin_set(value, *args)
      csv_file = File.join(File.dirname(__FILE__), '../lookup/collectionlist.csv')
      lines = CSV.read(csv_file, :headers=>true).map(&:to_hash)
      lines.map { |line| line[:Admin_Set] if line[:collection_handle].casecmp(value).zero? }
    end
  end
end
