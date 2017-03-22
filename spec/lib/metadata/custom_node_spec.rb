# frozen_string_literal: true
RSpec.describe Metadata::CustomNode do
  subject { custom_node.process_node(data) }

  let(:custom_node) { Metadata::CustomNode.new(work_type_config, node_config) }
  let(:mock_config) { File.open(File.join(File.dirname(__FILE__), '../../fixtures/mocks/default.yml')) { |f| YAML.safe_load(f) } }
  let(:work_type_config) { mock_config.reject { |k, _v| %w(migration_nodes custom_nodes).include?(k) } }
  let(:node_config) { mock_config['custom_nodes']['keyword'] }
  let(:data) { {} }

  it 'has an admin_set_id property' do
    expect(custom_node.admin_set_id).to be_truthy
  end

  it 'has an value_add_to_migration property' do
    expect(custom_node.value_add_to_migration).to be_truthy
  end

  it 'has an value_from_node_property property' do
    expect(custom_node.value_from_node_property).to be_truthy
  end

  it 'can process_node' do
    expect(subject.dig('default_work', 'keyword')).to be_truthy
  end

  context 'with a FixNum as the value' do
    before :each do
      node_config['value'] = 1
    end

    it 'can process_node' do
      expect(subject.dig('default_work', 'keyword')).to be_truthy
      expect(subject.values.first).to eq 'keyword' => [1]
    end
  end

  context 'with a string array method' do
    it 'can process_node' do
      allow(Mapping::Keyword).to receive(:unprocessed).and_return(%w(one two))
      expect(subject.values.length).to eq 1
      expect(subject.values.first).to eq 'keyword' => %w(one two)
    end
  end

  context 'with a hash array method' do
    it 'can process_node' do
      allow(Mapping::Keyword).to receive(:unprocessed).and_return(field_name: 'blah', value: 'foo')
      expect(subject.dig('default_work', 'blah')).to be_truthy
      expect(subject).to eq 'default_work' => { 'blah' => ['foo'] }
    end
    context 'setting a String field' do
      before :each do
        node_config['field']['type'] = 'String'
      end

      it 'can process_node' do
        allow(Mapping::Keyword).to receive(:unprocessed).and_return(field_name: 'blah', value: 'foo')
        expect(subject.dig('default_work', 'blah')).to be_truthy
        expect(subject).to eq 'default_work' => { 'blah' => 'foo' }
      end
    end
  end
end
