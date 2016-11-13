require 'item'

class Bag
  attr_accessor :path

  def initialize(path)
    @path = path
  end

  def bagit
    @bagit ||= File.readlines(File.join(@path, 'bagit.txt'))
  end

  def manifest
    @manifest ||= load_manifest
  end

  def item
    @item ||= Item.new @path
  end

  def data_paths
    @data_paths ||= load_data_paths
  end

  def files
    @files ||= load_files
  end

  private

  def load_manifest
    md5_filename = File.join(@path, 'manifest-md5.txt')
    raise "Missing manifest-md5.txt" unless File.exists? md5_filename
    h = {}
    File.readlines(md5_filename).each do |line|
      hash, path = line.split(' ')
      h[path] = hash
    end
    h
  end

  def load_data_paths
    manifest.keys.select {|key| key.match(/data\/.*\//) != nil }
  end

  def load_files
    load_data_paths.reject {|key| key.match(/-metadata.xml$/)}
  end
end