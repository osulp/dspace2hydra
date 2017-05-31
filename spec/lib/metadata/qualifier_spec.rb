# frozen_string_literal: true
class QualifierSomeClass
  def self.test_method(value, *args)
    return "executed test_method with value #{value}" if args.empty?
    return "executed test_method with value #{value} and #{args.join(',')}" unless args.nil?
  end
end

RSpec.describe Metadata::Qualifier do
  subject { Metadata::Qualifier.new 'bogus', qualifier, work_type_config, node_config, value }
  let(:mock_config) { File.open(File.join(File.dirname(__FILE__), '../../fixtures/mocks/default.yml')) { |f| YAML.safe_load(f) } }

  let(:qualifier) { 'default' }
  let(:work_type_config) { mock_config.reject { |k, _v| %w(migration_nodes custom_nodes).include?(k) } }
  let(:node_config) { mock_config['migration_nodes']['description'] }
  let(:value) { 'grimey' }

  it 'has a qualifier' do
    expect(subject.instance_variable_get(:@qualifier)).to eq qualifier
  end

  it 'has a value' do
    expect(subject.instance_variable_get(:@value)).to eq value
  end

  it "has a method configured for 'default'" do
    expect(subject.method).to be_truthy
  end

  it 'has a value_add_to_migration' do
    expect(subject.value_add_to_migration).to eq 'except_empty_value'
  end

  it 'has a field_name' do
    expect(subject.field_name).to eq node_config.dig('qualifiers', qualifier, 'field', 'name')
  end

  it 'has a field_property' do
    expect(subject.field_property).to eq node_config.dig('field', 'property')
  end

  it 'has a field_type' do
    expect(subject.field_type).to eq node_config.dig('field', 'type')
  end

  it 'is default' do
    expect(subject.default?).to be_truthy
  end

  context 'with a qualifier' do
    let(:qualifier) { 'digitization' }
    before :each do
      node_config['qualifiers']['digitization']['method'] = 'QualifierSomeClass.test_method'
    end

    it 'has a form_field_name' do
      expect(subject.field_name).to eq node_config.dig('qualifiers', 'digitization', 'field', 'name')
    end

    it 'has a method' do
      expect(subject.method).to eq node_config.dig('qualifiers', 'digitization', 'method')
      expect(subject.method).to be_truthy
    end

    it 'can run_method' do
      expect(subject.run_method).to eq 'executed test_method with value grimey'
    end

    context 'with method args' do
      before :each do
        node_config['qualifiers']['digitization']['method'] = %w(QualifierSomeClass.test_method arg1 arg2)
      end
      it 'can run_method' do
        expect(subject.run_method).to eq 'executed test_method with value grimey and arg1,arg2'
      end
    end

    context 'with a missing configuration' do
      let(:qualifier) { 'doesntexist' }
      it 'logs a fatal message and raises an exception' do
        expect { subject.run_method }.to raise_error
      end
    end
  end

  context 'when get_configuration fails' do
    before :each do
      allow(subject).to receive(:get_configuration) { raise }
    end
    context '#value_add_to_migration' do
      it 'raises error' do
        expect { subject.value_add_to_migration }.to raise_error(StandardError)
      end
    end
    context '#field_name' do
      it 'raises error' do
        expect { subject.field_name }.to raise_error(StandardError)
      end
    end
    context '#field_property' do
      it 'raises error' do
        expect { subject.field_property }.to raise_error(StandardError)
      end
    end
    context '#field_type' do
      it 'raises error' do
        expect { subject.field_type }.to raise_error(StandardError)
      end
    end
    context '#method' do
      it 'raises error' do
        expect { subject.method }.to raise_error(StandardError)
      end
    end
  end
end
