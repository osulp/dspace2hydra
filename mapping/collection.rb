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
    def self.lookup_collection_name(value, *_args)
      names = Array.new
      csv_file = File.join(File.dirname(__FILE__), '../lookup/collectionlist.csv')
      # array of hash
      lines = CSV.read(csv_file, headers: true).map(&:to_hash)
      lines.each do |line|
        value.each do |handle|
          if line['collection_handle'].casecmp(handle) == 0
            puts line['collection_name']
            names << line['collection_name']
          end
        end
      end
      return names
    end
  end
end
