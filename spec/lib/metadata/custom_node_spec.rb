class CustomNodeSomeClass
  extend Mapping::Extensions::BasicValueHandler
  def self.test_method(value, *_args)
    "executed test_method with value #{value}"
  end

  def self.test_array_string_method(_value, *_args)
    %w(one two)
  end

  def self.test_array_hash_method(_value, *_args)
    [{ field_name: 'field', value: 'value1' }, { field_name: 'field2', value: 'value2' }]
  end
end

RSpec.describe Metadata::CustomNode do
  subject { Metadata::CustomNode.new(work_type, config).process_node(data) }

  let(:work_type) { 'default_work' }
  let(:config) do
    {
      'form_field' => "%{work_type}['%{form_field_name}'][]",
      'method' => 'CustomNodeSomeClass.test_method',
      'form_field_name' => 'field_name',
      'value' => 'testeroni'
    }
  end
  let(:data) { {} }

  it 'can process_node' do
    expect(subject.key?("default_work['field_name'][]")).to be_truthy
  end

  context 'with a FixNum as the value' do
    let(:config) do
      {
        'form_field' => '%{form_field_name}',
        'method' => 'CustomNodeSomeClass.unprocessed',
        'form_field_name' => 'agreement',
        'value' => 1
      }
    end

    it 'can process_node' do
      expect(subject.key?('agreement')).to be_truthy
      expect(subject.values.first).to eq [1]
    end
  end

  context 'with a string array method configured' do
    let(:config) do
      {
        'method' => 'CustomNodeSomeClass.test_array_string_method',
        'form_field' => "%{work_type}['%{form_field_name}'][]",
        'form_field_name' => 'field_name',
        'value' => 'blah'
      }
    end

    it 'can process_node' do
      expect(subject.values.length).to eq 1
      expect(subject.values.first).to eq %w(one two)
    end
  end
  context 'with a hash array method configured' do
    let(:config) do
      {
        'method' => 'CustomNodeSomeClass.test_array_hash_method',
        'form_field' => "%{work_type}['%{form_field_name}'][]",
        'form_field_name' => 'field_name',
        'value' => 'blah'
      }
    end

    it 'can process_node' do
      expect(subject.values.length).to eq 2
      expect(subject.keys.length).to eq 2
    end
  end
end
