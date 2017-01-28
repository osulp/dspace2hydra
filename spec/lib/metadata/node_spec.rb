class NodeSomeClass
  def self.test_method(value, *args)
    return "executed test_method with value #{value}" if args.empty?
    return "executed test_method with value #{value} and #{args.join(',')}" unless args.nil?
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
      "qualifiers" =>  {
        "default" => {
          "form_field" => "generic_work['field_name'][]"
        },
        "test_qualifier" => {
          "form_field" => "generic_work['test_field_name'][]",
          "method" => "NodeSomeClass.test_method"
        }
      }
    }
  }

  it "has a qualifier" do
    expect(subject.qualifier).to be_a_kind_of Metadata::Qualifier
  end

  it "has an xpath" do
    expect(subject.xpath).to eq config['xpath']
  end

  it "has a method" do
    expect(subject.has_method?).to be_falsey
    expect(subject.method).to eq config['method']
  end

  it "fails to run_method because it is not configured for the node or 'default'" do
    expect{ subject.run_method }.to raise_error(StandardError)
  end

  it "has a qualifier with a form_field" do
    expect(subject.form_field).to eq config['qualifiers']['default']['form_field']
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
        "qualifiers" =>  {
          "default" => {
            "form_field" => "generic_work['field_name'][]"
          },
          "test_qualifier" => {
            "form_field" => "generic_work['test_field_name'][]",
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
          "method" => ["NodeSomeClass.test_method", "arg1", "arg2"],
          "qualifiers" =>  {
            "default" => {
              "form_field" => "generic_work['field_name'][]"
            },
            "test_qualifier" => {
              "form_field" => "generic_work['test_field_name'][]",
              "method" => "NodeSomeClass.test_method"
            }
          }
        }
      }
      it "can run_method" do
        expect(subject.has_method?).to be_truthy
        expect(subject.run_method).to eq "executed test_method with value A value and arg1,arg2"
      end
    end
  end
end
