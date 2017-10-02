# frozen_string_literal: true
class Item
  include Loggable
  attr_reader :path

  def initialize(path, config)
    @logger = Logging.logger[self]
    @path = path
    @config = config
  end

  def metadata
    @metadata ||= build_metadata_hash
  end

  def metadata_xml
    @metadata_xml ||= File.open(metadata_xml_path) { |f| Nokogiri::XML(f) }
  end

  def object_properties
    @object_properties ||= object_properties_hash
  end

  def item_id
    object_properties['objectId'].first.tr('/', '-')
  end

  def owner_id
    log_and_raise 'missing ownerId in this items object.properties' if object_properties['ownerId'].nil?
    object_properties['ownerId'].first
  end

  def other_ids
    object_properties['otherIds'] || []
  end

  def collection_handles
    [owner_id] + other_ids
  end

  def custom_metadata
    @custom_metadata ||= build_custom_metadata_hash
  end

  private

  def migration_nodes
    log_and_raise "missing 'migration_nodes' configuration" if @config['migration_nodes'].nil?
    @config['migration_nodes']
  end

  def custom_nodes
    log_and_raise "missing 'custom_nodes' configuration" if @config['custom_nodes'].nil?
    @config['custom_nodes']
  end

  def metadata_xml_path
    File.join(@path, CONFIG.dig('bag', 'item', 'metadata_file'))
  end

  ##
  # Get the configurations set for this work type, excluding the node migration specific configurations.
  # This is intended to be used for setting default configurations which can eventually be overridden
  # by any nested node or qualifier configuration.
  # The following example shows 'my_configuration' with a default value at the work type configuration
  # level, and the migration node 'keyword' having it overridden while 'visibility' would just inherit the
  # default 'my_configuration' value.
  #
  # ex.
  # my_configuration: 'some default value right here'
  #     migration_nodes:
  #         keyword:
  #             my_configuration: 'overridden'
  #         visibility:
  #             ...
  def work_type_config
    @work_type_config ||= @config.reject { |k, _v| %w(custom_nodes migration_nodes).include?(k) }
  end

  ##
  # Load the object.properties as a hash with the key and an array of values
  # @returns [Hash<String,Array<String>>] a hash with key=>array of strings
  def object_properties_hash
    h = {}
    File.readlines(File.join(@path, CONFIG.dig('bag', 'item', 'object_properties_file'))).each do |line|
      key, *rest = line.split(' ')
      h[key] = rest.map { |e| e.split(',') }.flatten
    end
    h
  end

  def build_custom_metadata_hash
    h = {}
    custom_nodes.each do |key, node_config|
      h[key] ||= []
      h[key] << Metadata::CustomNode.new(self, key, work_type_config, node_config)
    end
    h
  end

  ##
  # Build a hash of Metadata::Nodes transformed using the appropriate configuration for this type of Item.
  def build_metadata_hash
    h = {}
    # temp_xml will be the target of mutation during this process
    temp_xml = metadata_xml.clone
    transform_configured_nodes temp_xml, h, work_type_config, migration_nodes
    clear_empty_text_nodes temp_xml
    # Nokogiri::XML doesn't have a method to handle evaluating if a document has valid children,
    # so creating a new document from the mutated temp_xml is effective, albeit hackish
    remaining_xml = Nokogiri::XML.parse temp_xml.to_xml
    # TODO: consider making this error configurable by Item type
    raise StandardError, "#{work_type_config.dig('work_type')} : #{metadata_xml_path} unhandled nodes:\n#{remaining_xml.to_xml}" unless remaining_xml.root.children.empty?
    h
  end

  ##
  # Nokogiri nodes, when removed from a document, leave behind empty string nodes with newlines. Remove the content
  # of each to aid in evaluating if there are valid nodes left to process.
  #
  # This method *intentionally mutates* `xml_doc` so that it is left without invalid empty text nodes.
  # @param [Nokogiri::XML::Document] xml_doc - the xml document to clean
  def clear_empty_text_nodes(xml_doc)
    xml_doc.root.children.each { |t| t.content = t.content.gsub(/^\n\s*\n*$/, '') }
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
  # @param [Hash] work_type_config - the configurations for this work_type
  # @param [Hash] node_configs - this items configuration, such as "etd". @see config/etd.yml
  def transform_configured_nodes(xml_doc, h, work_type_config, node_configs)
    node_configs.each do |key, node_config|
      log_and_raise "missing migration_nodes.#{key}.xpath configuration" if node_config['xpath'].nil? || node_config['xpath'].empty?
      h[key] ||= []
      xml_doc.xpath(node_config['xpath']).each do |node|
        h[key] << Metadata::Node.new(node, key, work_type_config, node_config)
        node.remove
      end
    end
  end
end
