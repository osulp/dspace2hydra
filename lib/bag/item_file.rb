class ItemFile
  attr_accessor :full_path

  def initialize(full_path)
    @full_path = full_path
  end

  ##
  # Return the file name without the extension
  # @returns [String] the filename without the extension
  def file_name
    File.basename @full_path, ".*"
  end

  ##
  # Return a File object to the full path of this ItemFile
  # @returns [File] file object
  def file
    File.new @full_path
  end

  def description
    @description ||= metadata_xml.xpath(CONFIG['bag']['item']['item_file']['description_xpath']).children.first.to_s
  end

  def name
    @name ||= metadata_xml.xpath(CONFIG['bag']['item']['item_file']['name_xpath']).children.first.to_s
  end

  def sequence_id
    @sequence_id ||= metadata_xml.xpath(CONFIG['bag']['item']['item_file']['sequence_id_xpath']).children.first.to_s
  end

  def source
    @source ||= metadata_xml.xpath(CONFIG['bag']['item']['item_file']['source_xpath']).children.first.to_s
  end

  def metadata_xml
    metadata_filename = CONFIG['bag']['item']['item_file']['metadata_file_name_template'].gsub "{item_file_name}", file_name
    @metadata_xml ||= File.open(File.join(File.dirname(@full_path), metadata_filename)) { |f| Nokogiri::XML(f) }
  end
end
