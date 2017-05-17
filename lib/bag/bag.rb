# frozen_string_literal: true
class Bag
  include Loggable

  attr_reader :path, :type_config, :item_cache_path

  def initialize(path, application_config, type_config)
    @logger = Logging.logger[self]
    @path = path
    @application_config = application_config
    @type_config = type_config
    @item_cache_path = File.join(File.dirname(__FILE__), "../../#{@application_config['cache_and_logging_path']}/ITEM@#{item.item_id}")
    Dir.mkdir @item_cache_path unless File.exist? @item_cache_path
  end

  def bagit
    @bagit ||= File.readlines(File.join(@path, @application_config['bag']['bagit_file']))
  end

  def manifest
    @manifest ||= load_manifest
  end

  def item
    @item ||= Item.new File.join(@path, @application_config['bag']['item']['directory']), @type_config
  end

  def data_paths
    @data_paths ||= load_data_paths
  end

  def upload_configs
    @upload_configs ||= @type_config['upload_data']
  end

  def files
    @files ||= load_files
  end

  def files_for_upload
    @files_for_upload ||= filter_upload_files
  end

  private

  ##
  # Load the manifest as a hash with the path to each file as the key, and the hash code as the value
  # @returns [Hash<String, String>] a hash of the path => hashcode for each file in the manifest
  def load_manifest
    manifest_file = File.join(@path, @application_config['bag']['manifest_file'])
    raise "Missing #{manifest_file}" unless File.exist? manifest_file
    h = {}
    File.readlines(manifest_file).each do |line|
      hash, path = line.split(' ')
      h[path] = hash
    end
    h
  end

  ##
  # Load all of the paths to data files from the manifest
  # @returns [Array<String>] an array of string paths from the manifest
  def load_data_paths
    manifest.keys.select { |key| !key.match(/#{@application_config['bag']['item']['item_file']['directory_pattern']}/).nil? }
  end

  ##
  # Instantiate a list of ItemFile ordered by their sequence_id
  # @returns [Array<ItemFile>] an array of ItemFile objects
  def load_files
    pattern = @application_config['bag']['item']['item_file']['metadata_file_name_template'].gsub '{item_file_name}', ''
    files = load_data_paths.reject { |key| key.match(/#{pattern}$/) }.map do |file_path|
      ItemFile.new File.join(@path, file_path)
    end
    files.sort_by!(&:sequence_id)
  end

  ##
  # Filter the list of data files to include only files that should be uploaded
  # based on the configuration
  # @returns [Array<ItemFile>] an array of ItemFile objects
  def filter_upload_files
    upload_directories = upload_configs.map { |config| config['directory'] }
    upload_files = files.select do |item_file|
      in_upload_directory = upload_directories.include?(item_file.parent_directory)
      @logger.warn("File configuration does not include the directory, will not upload: #{item_file.full_path}") unless in_upload_directory
      next unless in_upload_directory
      ignored = item_file_ignored?(item_file)
      @logger.warn("File configuration found to explicitly ignore uploading: #{item_file.full_path}") if ignored
      next(!ignored)
    end
    upload_files.each { |item_file| @logger.info("Identified file to be uploaded: #{item_file.full_path}") }
    upload_files
  end

  ##
  # Determing if the item_file supplied matches one of the ignore_files regex in the configuration
  # for this item_file's parent_directory.
  # @param [ItemFile] item_file - the item file to evalute
  # @returns [Boolean] - true if the item_file.name is a match for any of the ignore_files configuration
  def item_file_ignored?(item_file)
    upload_config = upload_configs.first { |c| c['directory'].include?(item_file.parent_directory) }
    upload_config['ignore_files'] ||= []
    upload_config['ignore_files'].any? { |regex| item_file.name.match(/#{regex}/i) }
  end
end
