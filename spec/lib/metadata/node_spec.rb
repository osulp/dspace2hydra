class NodeSomeClass
  def self.test_method(value, *args)
    "executed test_method with value #{value}"
  end

  def self.test_array_string_method(value, *args)
    return ["one", "two"]
  end

  def self.test_array_hash_method(value, *args)
    return [{field_name: "field", value: "value1"},{field_name: "field2", value:"value2"}]
  end
end

RSpec.describe Metadata::Node do
  subject { Metadata::Node.new xml_node, field, config }

  let(:xml_doc) { Nokogiri::XML('<metadata><value schema="dc" element="some_element">A value</value></metadata>') }
  let(:xml_node) { xml_doc.at_xpath(config['xpath']) }
  let(:field) { "some_element" }
  let(:config) {
    {
      "xpath" => "//metadata/value[@element='some_element']",
      "form_field" => "generic_work['%{form_field_name}'][]",
      "method" => "NodeSomeClass.test_method",
      "qualifiers" =>  {
        "default" => {
          "form_field_name" => "field_name"
        },
        "test_qualifier" => {
          "form_field_name" => "test_field_name",
        }
      }
    }
  }
  let(:data){{}}

  it "has a qualifier" do
    expect(subject.qualifier).to be_a_kind_of Metadata::Qualifier
  end

  it "has an xpath" do
    expect(subject.xpath).to eq config['xpath']
  end

  it "has a method" do
    expect(subject.has_method?).to be_truthy
    expect(subject.method).to eq config['method']
  end

  it "has a qualifier with a form_field" do
    expect(subject.form_field).to eq "generic_work['field_name'][]"
  end

  it "has a form_field_name supplied to it" do
    expect(subject.form_field('blahblah')).to eq "generic_work['blahblah'][]"
  end

  it "can process_node" do
    result = subject.process_node(data)
    expect(result.has_key?("generic_work['field_name'][]")).to be_truthy
  end

  context "with qualifier in the node" do
    let(:xml_doc) { Nokogiri::XML('<metadata><value schema="dc" element="some_element" qualifier="test_qualifier">Graduation: 2245</value></metadata>') }
    it "has a qualifier" do
      expect(subject.qualifier).to be_a_kind_of Metadata::Qualifier
      expect(subject.content).to eq "Graduation: 2245"
    end

    it "can run_method" do
      expect(subject.run_method).to eq "executed test_method with value Graduation: 2245"
    end
  end

  context "with a default method configured" do
    let(:config) {
      {
        "xpath" => "//metadata/value[@element='some_element']",
        "method" => "NodeSomeClass.test_method",
        "form_field" => "generic_work['%{form_field_name}'][]",
        "qualifiers" =>  {
          "default" => {
            "form_field_name" => "field_name"
          },
          "test_qualifier" => {
            "form_field_name" => "test_field_name",
            "method" => "NodeSomeClass.test_method"
          }
        }
      }
    }

    it "can run_method" do
      expect(subject.has_method?).to be_truthy
      expect(subject.run_method).to eq "executed test_method with value A value"
    end

    context "with args on the method" do
      let(:config) {
        {
          "xpath" => "//metadata/value[@element='some_element']",
          "method" => ["NodeSomeClass.test_array_string_method", "arg1", "arg2"],
          "form_field" => "generic_work['%{form_field_name}'][]",
          "qualifiers" =>  {
            "default" => {
              "form_field_name" => "field_name"
            },
            "test_qualifier" => {
              "form_field_name" => "test_field_name",
              "method" => ["NodeSomeClass.test_array_hash_method", "arg1", "arg2"]
            }
          }
        }
      }
      it "can run_method" do
        expect(subject.has_method?).to be_truthy
        expect(subject.process_node(data).values[0]).to eq ["one","two"]
      end

      context "and a specific qualifier" do
        let(:xml_doc) { Nokogiri::XML('<metadata><value schema="dc" element="some_element" qualifier="test_qualifier">Graduation: 2245</value></metadata>') }
        it "can run_method" do
          expect(subject.has_method?).to be_truthy
          expect(subject.process_node(data).values.length).to eq 2
          expect(subject.process_node(data).keys.length).to eq 2
        end
      end
    end
  end
end
