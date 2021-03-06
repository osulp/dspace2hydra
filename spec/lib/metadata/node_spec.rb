# frozen_string_literal: true
RSpec.describe Metadata::Node do
  subject { Metadata::Node.new(xml_node, field, work_type_config, node_config) }

  let(:mock_config) { File.open(File.join(File.dirname(__FILE__), '../../fixtures/mocks/default.yml')) { |f| YAML.safe_load(f) } }

  let(:type) { 'default' }
  let(:work_type_config) { mock_config.reject { |k, _v| %w(migration_nodes custom_nodes).include?(k) } }
  let(:node_config) { mock_config['migration_nodes']['description'] }

  let(:xml_doc) { Nokogiri::XML('<metadata><value schema="dc" element="description">A value</value></metadata>') }
  let(:xml_node) { xml_doc.at_xpath(node_config['xpath']) }
  let(:field) { 'description' }

  it 'has a default qualifier' do
    expect(subject.qualifier.default?).to be_truthy
  end

  it 'has the node value' do
    expect(subject.value).to eq 'A value'
  end

  context 'with qualifier in the node' do
    let(:xml_doc) { Nokogiri::XML('<metadata><value schema="dc" element="description" qualifier="digitization">digitization value</value></metadata>') }
    before :each do
      node_config['qualifiers']['digitization']['method'] = 'Mapping::Description.unprocessed'
    end

    it 'hass a non-default qualifier' do
      expect(subject.qualifier.default?).to be_falsey
    end
  end
end
