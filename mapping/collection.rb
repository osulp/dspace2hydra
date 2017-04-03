# frozen_string_literal: true
module Mapping
  class Collection
    require 'csv'
    require 'yaml'

    extend Extensions::BasicValueHandler

    ##
    # 
    #
    # @param[String] value - An array of collection handles passed from CustomNode 
    # @param[Array] *args - 
    # return - 
    def self.lookup_collection_name(value, *args)
      csv_file = File.join(File.dirname(__FILE__), '../lookup/collectionlist.csv')
      # array of hash
      lines = CSV.read(csv_file, :headers=>true).map(&:to_hash)
      lines.map { |line| line[:collection_name] if line[:collection_handle].casecmp(value).zero? }
    end
  end
end
