# frozen_string_literal: true
class QualifierSomeClass
  def self.test_method(value, *args)
    return "executed test_method with value #{value}" if args.empty?
    return "executed test_method with value #{value} and #{args.join(',')}" unless args.nil?
  end
end

RSpec.describe Metadata::Qualifier do
  subject { Metadata::Qualifier.new 'bogus', type, work_type_config, node_config }
  let(:mock_config) { File.open(File.join(File.dirname(__FILE__), '../../fixtures/mocks/default.yml')) { |f| YAML.safe_load(f) } }

  let(:type) { 'default' }
  let(:work_type_config) { mock_config.reject { |k, _v| %w(migration_nodes custom_nodes).include?(k) } }
  let(:node_config) { mock_config['migration_nodes']['description'] }

  it 'has a type' do
    expect(subject.type).to eq type
  end

  it "has a method configured for 'default'" do
    expect(subject.method).to be_truthy
  end

  it 'has a value_add_to_migration' do
    expect(subject.value_add_to_migration).to eq 'except_empty_value'
  end

  it 'has a form_field_name' do
    expect(subject.form_field_name).to eq node_config['qualifiers'][type]['form_field_name']
  end

  it 'is default' do
    expect(subject.default?).to be_truthy
  end

  context 'with a qualifier' do
    let(:type) { 'digitization' }
    before :each do
      node_config['qualifiers']['digitization']['method'] = 'QualifierSomeClass.test_method'
    end

    it 'has a form_field_name' do
      expect(subject.form_field_name).to eq node_config['qualifiers']['digitization']['form_field_name']
    end

    it 'has a method' do
      expect(subject.method).to eq node_config['qualifiers']['digitization']['method']
      expect(subject.method).to be_truthy
    end

    it 'can run_method' do
      expect(subject.run_method('test')).to eq 'executed test_method with value test'
    end

    context 'with method args' do
      before :each do
        node_config['qualifiers']['digitization']['method'] = %w(QualifierSomeClass.test_method arg1 arg2)
      end
      it 'can run_method' do
        expect(subject.run_method('test')).to eq 'executed test_method with value test and arg1,arg2'
      end
    end
  end
end
