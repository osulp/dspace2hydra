class Bag
  attr_reader :path, :config

  def initialize(path, config)
    @path = path
    @config = config
  end

  def bagit
    @bagit ||= File.readlines(File.join(@path, CONFIG['bag']['bagit_file']))
  end

  def manifest
    @manifest ||= load_manifest
  end

  def item
    @item ||= Item.new File.join(@path, CONFIG['bag']['item']['directory']), @config
  end

  def data_paths
    @data_paths ||= load_data_paths
  end

  def files
    @files ||= load_files
  end

  private

  ##
  # Load the manifest as a hash with the path to each file as the key, and the hash code as the value
  # @returns [Hash<String, String>] a hash of the path => hashcode for each file in the manifest
  def load_manifest
    manifest_file = File.join(@path, CONFIG['bag']['manifest_file'])
    raise "Missing #{manifest_file}" unless File.exists? manifest_file
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
    manifest.keys.select {|key| key.match(/#{CONFIG['bag']['item']['item_file']['directory_pattern']}/) != nil }
  end

  ##
  # Instantiate a list of ItemFile ordered by their sequence_id
  # @returns [Array<ItemFile>] an array of ItemFile objects
  def load_files
    pattern = CONFIG['bag']['item']['item_file']['metadata_file_name_template'].gsub "{item_file_name}", ""
    files = load_data_paths.reject {|key| key.match(/#{pattern}$/)}.map do |file_path|
      ItemFile.new File.join(@path, file_path)
    end
    files.sort_by! { |f| f.sequence_id }
  end
end