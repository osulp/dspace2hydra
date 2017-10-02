# frozen_string_literal: true
module Mapping
  class AdminSet
    require 'csv'
    require 'yaml'

    extend Extensions::BasicValueHandler

    CACHE_FILE = '../cache/admin_sets.yml'
    CSV_FILE = '../lookup/collectionlist.csv'

    ##
    # Locate adminset with the passing owning_collection handle
    #
    # @param[String] value - handle of owning collection
    # @param[Array] *args - properties passed to the method
    # return - adminset_id, a blank adminset_id maps to 'Default' adminset in Hyrax
    def self.lookup_admin_set(value, *_args)
      csv_file = File.join(File.dirname(__FILE__), CSV_FILE)
      lines = CSV.read(csv_file, headers: true, encoding: 'UTF-8').map(&:to_hash)
      line = lines.find { |l| l['collection_handle'].casecmp(value).zero? }
      raise StandardError, "did not find admin_set_name for collection_handle '#{value}' in collectionlist.csv, specify 'Default' if you intend on using the Default Admin Set." if line.nil? || line['Admin_Set_Name'].to_s.empty?
      admin_set_name = line['Admin_Set_Name']
      # Currently in Hyrax, the default AdminSet is special, it has no ID, passing an empty admin_set_id associates a work to the default one.
      # We want to explicitly map to 'default', and error on empty/missing mapped rows in the CSV
      return '' if admin_set_name.casecmp('default').zero?

      items = load_admin_sets_cache
      found = items['admin_sets'].find { |item| item['title'].any? { |t| t.casecmp(admin_set_name).zero? } } if items
      raise StandardError, "#{admin_set_name} not found on server, unable to process this item." if found.nil?
      found['id']
    end

    private

    def self.load_admin_sets_cache
      File.open(File.join(File.dirname(__FILE__), CACHE_FILE), 'r') do |file|
        return YAML.safe_load(file)
      end
    end
  end
end
