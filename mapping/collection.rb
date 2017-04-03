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
      csv_file = File.join(File.dirname(__FILE__), '../lookup/collectionlist.csv')
      # array of hash
      lines = CSV.read(csv_file, headers: true).map(&:to_hash)
      lines.select { |l| value.to_s.downcase.include? l['collection_handle'].downcase }.map { |l| l['collection_name'] }
    end
  end
end
