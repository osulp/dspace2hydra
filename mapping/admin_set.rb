# frozen_string_literal: true
module Mapping
  class AdminSet
    require 'csv'
    require 'yaml'

    extend Extensions::BasicValueHandler

    ##
    # Convert data in a csv file to hash in YAML format
    #
    # @param[String] value - the path to the csv file
    # return - [Hash] of YAML
    def csv_to_yaml(value)
      data = CSV.read (value, :headers => true).map(&:to_hash)
      data.to_yaml
    end

    ##
    # Locate adminset with the passing owning_collection handle
    #
    # @param[String] value - handle of owning collection
    # return - admin_set 
    def lookup_admin_set(value)
      lookup = csv_to_yaml('../../lookup/collectionlist.csv')
      lookup.select { |l| l[:collection_handle] == value }
    end 
  end
end
