# frozen_string_literal: true
module Mapping
  class Community
    require 'csv'
    require 'yaml'

    extend Extensions::BasicValueHandler

    ##
    #
    #
    # @param[String] value - An array of collection handles passed from CustomNode
    # @param[Array] *args -
    # return -
    def self.lookup_community_names(value, *_args)
      csv_file = File.join(File.dirname(__FILE__), '../lookup/collectionlist.csv')
      # array of hash
      lines = CSV.read(csv_file, headers: true).map(&:to_hash)
      lines.select { |l| value.any? { |v| l['collection_handle'].casecmp(v).zero? } }.map { |l| l['community_name'] }
    end
  end
end
