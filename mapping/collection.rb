# frozen_string_literal: true
module Mapping
  class Collection
    require 'csv'
    require 'yaml'

    extend Extensions::BasicValueHandler
    CSV_FILE = '../lookup/collectionlist.csv'

    ##
    #
    #
    # @param[String] value - An array of collection handles passed from CustomNode
    # @param[Array] *args -
    # return -
    def self.lookup_collection_names(value, *_args)
      csv_file = File.join(File.dirname(__FILE__), CSV_FILE)
      # array of hash
      lines = CSV.read(csv_file, headers: true).map(&:to_hash)
      lines.select { |l| value.any? { |v| l['collection_handle'].casecmp(v).zero? } }.map { |l| l['collection_name'] }
    end
  end
end
