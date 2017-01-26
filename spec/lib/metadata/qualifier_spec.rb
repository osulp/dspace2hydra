RSpec.describe Metadata::Qualifier do
  subject { Metadata::Qualifier.new type, config }

  let(:type) { "default" }
  let(:config) {
    {
      "default" => {
        "form_field" => "generic_work['field_name'][]"
      },
      "test_qualifier" => {
        "form_field" => "generic_work['test_field_name'][]"
      }
    }
  }

  it "has a type" do
    expect(subject.type).to eq type
  end

  it "has an form_field" do
    expect(subject.form_field).to eq config['default']['form_field']
  end

  it "is default" do
    expect(subject.default?).to be_truthy
  end
end
