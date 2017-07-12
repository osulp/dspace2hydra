# frozen_string_literal: true
module Extract
  include Loggable

  attr_reader :bags

  # For a group of bags, extract each item's XML metadata into a Hash, then add to Array of all records
  def extract_records_metadata(bags)
    records = Array.new(0)

    # Build an array of item hashes from record metadata
    bags.each do |bag|
      xml = bag.item.metadata_xml
      item_elements_with_qualifiers = Array.new (0)

      # Find all elements (with any qualifiers) in metadata
      xml.xpath("//metadata/value").each do |element|
        item_elements_with_qualifiers << element.xpath("@element").text + '_' + element.xpath("@qualifier").text
      end

      # Set id and filename values directly, filename matches 'extract_files' filename output
      item_hash = Hash.new
      item_hash[:id] = [bag.item.item_id]
      item_hash[:filename] = bag.files_for_upload.map { |f| "#{bag.item.item_id}_#{f.name}" }

      # Iterate over unique elements in metadata to pull out all values
      item_elements_with_qualifiers.uniq.each do |name|
        values = Array.new (0)
        element_name = name.split('_').first
        element_qualifier = (name.split('_').last == name.split('_').first) ? nil : name.split('_').last

        if element_qualifier.nil?
          xml.xpath("//metadata/value[@element='#{element_name}']").each do |e|
            values << e.text
          end
        else
          xml.xpath("//metadata/value[@element='#{element_name}'][@qualifier='#{element_qualifier}']").each do |e|
            values << e.text
          end
        end

        item_hash[name.chomp('_').to_sym] = values
      end

      records.push (item_hash)
    end

    return records
  end
end
