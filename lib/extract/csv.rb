# frozen_string_literal: true
module Extract
  include Loggable

  attr_reader :records

  # Using extracted records metadata, extract distinct_keys, set as headers, iterate over each record_hash and save
  def build_csv(records)
    # Find distinct keys across all metadata records
    distinct_keys = records.map(&:keys).flatten.uniq

    @logger.info("Building CSV file.")
    CSV.open(CONFIG['extract_csv'] + "/output.csv", "wb", {headers: true}) do |csv|
      csv << distinct_keys

      # iterate over each record
      records.sort_by {|r| r[:id]}.each do |rec|
        row = []

        # for each field, look for values, if none still output
        # for multiple values in same field, separate with ';'
        distinct_keys.each do |key|
          row_values = String.new("")

          if rec[key.to_sym].kind_of?(Array) then
            row_values << rec[key.to_sym].join('; ')
          else
            row_values << rec[key.to_sym].to_s
          end

          row << row_values
        end

        csv << row
      end
    end
    @logger.info("CSV file complete: " + CONFIG['extract_csv'] + "/output.csv")
  end
end
