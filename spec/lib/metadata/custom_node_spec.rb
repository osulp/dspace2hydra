class CustomNodeSomeClass
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
  subject { Metadata::CustomNode.new work_type, config }

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
    result = subject.process_node(data)
    expect(result.key?("default_work['field_name'][]")).to be_truthy
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
      result = subject.process_node(data)
      expect(result.values.length).to eq 1
      expect(result.values.first).to eq %w(one two)
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

    it 'can run_method' do
      expect(subject.process_node(data).values.length).to eq 2
      expect(subject.process_node(data).keys.length).to eq 2
    end
  end
end
