class Item
  attr_reader :path, :type

  def initialize(path, type)
    @path = path
    @type = type
  end

  def metadata
    @metadata ||= build_metadata_hash @type
  end

  def metadata_xml
    @metadata_xml ||= File.open(metadata_xml_path) { |f| Nokogiri::XML(f) }
  end

  def object_properties
    @object_properties ||= object_properties_hash
  end

  private

  def metadata_xml_path
    File.join(@path, CONFIG['bag']['item']['metadata_file'])
  end

  ##
  # Load the object.properties as a hash with the key and an array of values
  # @returns [Hash<String,Array<String>>] a hash with key=>array of strings
  def object_properties_hash
    h = {}
    File.readlines(File.join(@path, CONFIG['bag']['item']['object_properties_file'])).each do |line|
      key, *rest = line.split(' ')
      h[key] = rest.map { |e| e.split(',') }.flatten
    end
    h
  end

  ##
  # Build a hash of Metadata::Nodes transformed using the appropriate configuration for this type of Item.
  # @param [String] type - a "type" of configuration, such as "etd". @see .config.example.yml
  def build_metadata_hash(type)
    h = {}
    # temp_xml will be the target of mutation during this process
    temp_xml = metadata_xml.clone
    transform_configured_nodes temp_xml, h, type
    clear_empty_text_nodes temp_xml
    # Nokogiri::XML doesn't have a method to handle evaluating if a document has valid children,
    # so creating a new document from the mutated temp_xml is effective, albeit hackish
    remaining_xml = Nokogiri::XML.parse temp_xml.to_xml
    # todo : consider making this error configurable by Item type
    raise StandardError.new("#{metadata_xml_path} unhandled nodes:\n#{remaining_xml.to_xml}") unless remaining_xml.root.children.empty?
    h
  end

  ##
  # Nokogiri nodes, when removed from a document, leave behind empty string nodes with newlines. Remove the content
  # of each to aid in evaluating if there are valid nodes left to process.
  #
  # This method *intentionally mutates* `xml_doc` so that it is left without invalid empty text nodes.
  # @param [Nokogiri::XML::Document] xml_doc - the xml document to clean
  def clear_empty_text_nodes(xml_doc)
    xml_doc.root.children.each { |t| t.content = t.content.gsub(/^\n\s*\n*$/, "") }
  end

  ##
  # Iterate through this Item's configuration to extract each matching node from the source XML document,
  # translating each into an instance of Metadata::Node for further operation.
  #
  # This method *intentionally mutates* `xml_doc` so that is will retain any nodes which had no configuration for this
  # Item type. This leaves the calling method to determine if the remaining nodes should be ignored, processed differently,
  # or to raise an error and prevent operation.
  # @param [Nokogiri::XML::Document] xml_doc - The document to traverse
  # @param [Hash] h - the hash to fill with Metadata::Node objects
  # @param [String] type - a "type" of configuration, such as "etd". @see .config.example.yml
  def transform_configured_nodes(xml_doc, h, type)
    CONFIG[type].each do |key, value|
      h[key] ||= []
      xml_doc.xpath(value['xpath']).each do |node|
        h[key] << Metadata::Node.new(node, key, value)
        node.remove
      end
    end
  end
end