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
          "form_field" => "generic_work['test_field_name'][]"
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

  it "has a qualifier with a form_field" do
    expect(subject.form_field).to eq config['qualifiers']['default']['form_field']
  end

  context "with qualifier in the node" do
    let(:xml_doc) { Nokogiri::XML('<metadata><value schema="dc" element="some_element" qualifier="test_qualifier">Graduation: 2245</value></metadata>') }
    it "has a qualifier" do
      expect(subject.qualifier).to be_a_kind_of Metadata::Qualifier
      expect(subject.content).to eq "Graduation: 2245"
    end
  end
end
