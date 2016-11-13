require 'nokogiri'

class Item
  attr_accessor :path

  def initialize(path)
    @path = path
  end

  def metadata_xml
    @metadata_xml ||= File.open(File.join(@path, 'metadata.xml')) { |f| Nokogiri::XML(f) }
  end

  def object_properties
    @object_properties ||= object_properties_hash
  end

  private

  def object_properties_hash
    h = {}
    File.readlines(File.join(@path, 'object.properties')).each do |line|
      key, *rest = line.split(' ')
      h[key] = rest.map { |e| e.split(',') }.flatten
    end
    h
  end
end