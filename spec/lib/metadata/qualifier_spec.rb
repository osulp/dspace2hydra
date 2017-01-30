class QualifierSomeClass
  def self.test_method(value, *args)
    return "executed test_method with value #{value}" if args.empty?
    return "executed test_method with value #{value} and #{args.join(',')}" unless args.nil?
  end
end

RSpec.describe Metadata::Qualifier do
  subject { Metadata::Qualifier.new 'bogus', type, config }

  let(:type) { "default" }
  let(:config) {
    {
      "default" => {
        "form_field_name" => "field_name"
      },
      "test_qualifier" => {
        "form_field_name" => "test_field_name",
        "method" => "QualifierSomeClass.test_method"
      }
    }
  }

  it "has a type" do
    expect(subject.type).to eq type
  end

  it "does not have a method configured for 'default'" do
    expect(subject.has_method?).to be_falsey
  end

  it "fails to run_method because it is not configured for 'default'" do
    expect{ subject.run_method('blah') }.to raise_error(StandardError)
  end

  it "has a form_field_name" do
    expect(subject.form_field_name).to eq config['default']['form_field_name']
  end

  it "is default" do
    expect(subject.default?).to be_truthy
  end

  context "with a test_qualifier" do
    let(:type) { "test_qualifier" }
    it "has a form_field_name" do
      expect(subject.form_field_name).to eq config['test_qualifier']['form_field_name']
    end

    it "has a method" do
      expect(subject.method).to eq config['test_qualifier']['method']
      expect(subject.has_method?).to be_truthy
    end

    it "can run_method" do
      expect(subject.run_method('test')).to eq "executed test_method with value test"
    end

    context "with method args" do
      let(:config) {
        {
          "default" => {
            "form_field_name" => "field_name"
          },
          "test_qualifier" => {
            "form_field_name" => "test_field_name",
            "method" => ["QualifierSomeClass.test_method", "arg1", "arg2"]
          }
        }
      }

      it "can run_method" do
        expect(subject.run_method('test')).to eq "executed test_method with value test and arg1,arg2"
      end
    end
  end
end
