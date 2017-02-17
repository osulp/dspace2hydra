class NodeSomeClass
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

RSpec.describe Metadata::Node do
  subject { Metadata::Node.new(xml_node, field, work_type, config).process_node(data) }

  let(:xml_doc) { Nokogiri::XML('<metadata><value schema="dc" element="some_element">A value</value></metadata>') }
  let(:xml_node) { xml_doc.at_xpath(config['xpath']) }
  let(:field) { 'some_element' }
  let(:work_type) { 'default_work' }
  let(:config) do
    {
      'xpath' => "//metadata/value[@element='some_element']",
      'form_field' => "generic_work['%{form_field_name}'][]",
      'method' => 'NodeSomeClass.test_method',
      'qualifiers' => {
        'default' => {
          'form_field_name' => 'field_name'
        },
        'test_qualifier' => {
          'form_field_name' => 'test_field_name'
        }
      }
    }
  end
  let(:data) { {} }

  it 'can process_node' do
    expect(subject.key?("generic_work['field_name'][]")).to be_truthy
  end

  context 'with qualifier in the node' do
    let(:xml_doc) { Nokogiri::XML('<metadata><value schema="dc" element="some_element" qualifier="test_qualifier">Graduation: 2245</value></metadata>') }

    it 'can process_node' do
      expect(subject.values[0]).to eq ['executed test_method with value Graduation: 2245']
    end
  end

  context 'with a default method configured' do
    context 'with args on the method' do
      let(:config) do
        {
          'xpath' => "//metadata/value[@element='some_element']",
          'method' => ['NodeSomeClass.test_array_string_method', 'arg1', 'arg2'],
          'form_field' => "generic_work['%{form_field_name}'][]",
          'qualifiers' => {
            'default' => {
              'form_field_name' => 'field_name'
            },
            'test_qualifier' => {
              'form_field_name' => 'test_field_name',
              'method' => ['NodeSomeClass.test_array_hash_method', 'arg1', 'arg2']
            }
          }
        }
      end
      it 'can process_node' do
        expect(subject.values[0]).to eq %w(one two)
      end

      context 'and a specific qualifier' do
        let(:xml_doc) { Nokogiri::XML('<metadata><value schema="dc" element="some_element" qualifier="test_qualifier">Graduation: 2245</value></metadata>') }
        it 'can process_node' do
          expect(subject.values.length).to eq 2
          expect(subject.keys.length).to eq 2
        end
      end
    end
  end
end
