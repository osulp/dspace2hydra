class ItemFile
  attr_accessor :full_path, :metadata_full_path

  def initialize(full_path)
    @full_path = full_path
  end

  ##
  # Return the file name without the extension
  # @returns [String] the filename without the extension
  def file_name(at_path = nil)
    at_path ||= @full_path
    File.basename at_path, ".*"
  end

  ##
  # Return a File object to the full path of this ItemFile
  # @returns [File] file object
  def file(at_path = nil)
    at_path ||= @full_path
    File.new at_path
  end

  ##
  # Intends to make a temporary copy of the file using the filename from the ItemFile's metadata
  # so that uploading into Hydra will show the proper/meaningful filename.
  def copy_to_metadata_full_path
    FileUtils.copy @full_path, metadata_full_path
  end

  ##
  # Delete the temporary copy of the file and unset the class attribute
  def delete_metadata_full_path
    FileUtils.safe_unlink(metadata_full_path)
    @metadata_full_path = nil
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

  ##
  # Within the same directory as the original file, return a full path using the filename from this ItemFile's metadata
  def metadata_full_path
    @metadata_full_path ||= "#{File.dirname(@full_path)}/#{name}"
  end

  def metadata_xml
    metadata_filename = CONFIG['bag']['item']['item_file']['metadata_file_name_template'].gsub "{item_file_name}", file_name
    @metadata_xml ||= File.open(File.join(File.dirname(@full_path), metadata_filename)) { |f| Nokogiri::XML(f) }
  end
end
