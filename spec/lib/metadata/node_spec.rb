# frozen_string_literal: true
RSpec.describe Metadata::Node do
  subject { Metadata::Node.new(xml_node, field, work_type_config, node_config).process_node(data) }

  let(:mock_config) { File.open(File.join(File.dirname(__FILE__), '../../fixtures/mocks/default.yml')) { |f| YAML.safe_load(f) } }

  let(:type) { 'default' }
  let(:work_type_config) { mock_config.reject { |k, _v| %w(migration_nodes custom_nodes).include?(k) } }
  let(:node_config) { mock_config['migration_nodes']['description'] }

  let(:xml_doc) { Nokogiri::XML('<metadata><value schema="dc" element="description">A value</value></metadata>') }
  let(:xml_node) { xml_doc.at_xpath(node_config['xpath']) }
  let(:field) { 'description' }
  let(:data) { {} }

  it 'can process_node' do
    expect(subject).to eq('default_work[description][]' => ['A value'])
  end

  context 'with qualifier in the node' do
    let(:xml_doc) { Nokogiri::XML('<metadata><value schema="dc" element="description" qualifier="digitization">digitization value</value></metadata>') }
    before :each do
      node_config['qualifiers']['digitization']['method'] = 'Mapping::Description.unprocessed'
    end

    it 'can process_node' do
      expect(subject.values[0]).to eq ['digitization value']
    end
  end

  context 'with a default method configured' do
    context 'with args on the method' do
      before :each do
        node_config['method'] = ['Mapping::Description.prepend', 'test -> test:']
      end
      it 'can process_node' do
        expect(subject.values[0]).to eq ['test -> test: A value']
      end

      context 'and a specific qualifier' do
        let(:xml_doc) { Nokogiri::XML('<metadata><value schema="dc" element="description" qualifier="digitization">digitization value</value></metadata>') }
        before :each do
          node_config['qualifiers']['digitization']['method'] = ['Mapping::Description.prepend', 'test -> test:']
        end
        it 'can process_node' do
          expect(subject.values[0]).to eq ['test -> test: digitization value']
        end
      end
    end
  end
end
