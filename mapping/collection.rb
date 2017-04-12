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
    # return - An array of collection names
    def self.lookup_collection_name(value, *_args)
      names = Array.new
      csv_file = File.join(File.dirname(__FILE__), '../lookup/collectionlist.csv')
      # array of hash
      lines = CSV.read(csv_file, headers: true).map(&:to_hash)
      lines.each do |line|
        value.each do |handle|
          names << line['collection_name'] if line['collection_handle'].casecmp(handle).zero?
        end
      end
      return names
    end
  end
end
