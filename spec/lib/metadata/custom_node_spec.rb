# frozen_string_literal: true
RSpec.describe Metadata::CustomNode do
  subject { Metadata::CustomNode.new(work_type_config, node_config).process_node(data) }

  let(:mock_config) { File.open(File.join(File.dirname(__FILE__), '../../fixtures/mocks/default.yml')) { |f| YAML.safe_load(f) } }
  let(:work_type_config) { mock_config.reject { |k, _v| %w(migration_nodes custom_nodes).include?(k) } }
  let(:node_config) { mock_config['custom_nodes']['keyword'] }
  let(:data) { {} }

  it 'can process_node' do
    expect(subject.key?('default_work[keyword][]')).to be_truthy
  end

  context 'with a FixNum as the value' do
    before :each do
      node_config['value'] = 1
    end

    it 'can process_node' do
      expect(subject.key?('default_work[keyword][]')).to be_truthy
      expect(subject.values.first).to eq [1]
    end
  end

  context 'with a string array method' do
    it 'can process_node' do
      allow(Mapping::Keyword).to receive(:unprocessed).and_return(%w(one two))
      expect(subject.values.length).to eq 1
      expect(subject.values.first).to eq %w(one two)
    end
  end

  context 'with a hash array method' do
    it 'can process_node' do
      allow(Mapping::Keyword).to receive(:unprocessed).and_return(field_name: 'blah', value: 'foo')
      expect(subject.key?('default_work[blah][]')).to be_truthy
      expect(subject.values.first).to eq ['foo']
    end
  end
end
