class CustomNodeSomeClass
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

RSpec.describe Metadata::CustomNode do
  subject { Metadata::CustomNode.new work_type, config }

  let(:work_type) { "default_work" }
  let(:config) {
    {
      "form_field" => "%{work_type}['%{form_field_name}'][]",
      "method" => "CustomNodeSomeClass.test_method",
      "form_field_name" => "field_name",
      "value" => "testeroni"
    }
  }
  let(:data){{}}

  it "has a method" do
    expect(subject.has_method?).to be_truthy
    expect(subject.method).to eq config['method']
  end

  it "has a form_field_name supplied to it" do
    expect(subject.form_field('blahblah')).to eq "default_work['blahblah'][]"
  end

  it "can process_node" do
    result = subject.process_node(data)
    expect(result.has_key?("default_work['field_name'][]")).to be_truthy
  end

  context "with a string array method configured" do
    let(:config) {
      {
        "method" => "CustomNodeSomeClass.test_array_string_method",
        "form_field" => "%{work_type}['%{form_field_name}'][]",
        "form_field_name" => "field_name",
        "value" => "blah"
      }
    }

    it "can run_method" do
      expect(subject.has_method?).to be_truthy
      expect(subject.run_method).to eq ["one", "two"]
    end
  end
  context "with a hash array method configured" do
    let(:config) {
      {
        "method" => "CustomNodeSomeClass.test_array_hash_method",
        "form_field" => "%{work_type}['%{form_field_name}'][]",
        "form_field_name" => "field_name",
        "value" => "blah"
      }
    }

    it "can run_method" do
      expect(subject.has_method?).to be_truthy
      expect(subject.process_node(data).values.length).to eq 2
      expect(subject.process_node(data).keys.length).to eq 2
    end
  end
end
