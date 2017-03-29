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
  # Get ownerId from object_properties and parse DSpace owning collection name from lookup table 
  def owner_collection_name
    lookup = csv_to_yaml('../../lookup/collectionlist.csv')
    collection_list = lookup.select { |l| l[:collection_handle] == object_properties['ownerId'] }
    [ collection_list[:collection_name] ]
  end 

  ##
  # Get ownerId from object_properties and parse DSpace mapped collection name(s) from lookup table
  def other_collection_name
    lookup = csv_to_yaml('../../lookup/collectionlist.csv')
    other_id = object_properties['otherIds']
    if other_id.includes?(',')
      # other_id contains multiple collections
      other_coll_names = Array.new
      other_id.split(",").each do |handle|
        collection_list = lookup.select { |l| l[:collection_handle] == handle} 
        other_coll_names << collection_list[:collection_name]
      end
    else
      collection_list = lookup.select { |l| l[:collection_handle] == other_id }
      [ collection_list[:collection_name] ]
    end
  end

  def lookup_collection_name
    arr = Array.new
    arr << owner_collection_name
    arr.concat(other_collection_name)
  end
  end
end
