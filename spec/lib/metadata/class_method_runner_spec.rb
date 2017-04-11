# frozen_string_literal: true
class ClassMethodRunnerClassBase
  include Metadata::ClassMethodRunner
  include Loggable
  def initialize(work_type, config = {})
    @logger = Logging.logger[self]
    @config = config
    @work_type = work_type
  end

  def self.test_string_method(value, *_args)
    value
  end
end
class ClassMethodRunnerClass < ClassMethodRunnerClassBase
  def value_add_to_migration
    @config['value_add_to_migration'] ||= 'always'
  end
end

RSpec.describe Metadata::ClassMethodRunner do
  subject { ClassMethodRunnerClass.new(work_type, config) }
  let(:work_type) { 'blah_work' }
  let(:field_property) { '%{work_type}.%{field_name}' }
  let(:field_name) { 'some_field_name' }
  let(:field_property_name) { format(field_property, work_type: work_type, field_name: field_name) }
  let(:data) { {} }
  let(:existing_data) { { work_type => { field_name => ['already_migrated_data'] } } }
  let(:config) do
    {
      'method' => '',
      'field' => {
        'name' => field_name,
        'property' => field_property,
        'type' => 'Array'
      },
      'value' => ''
    }
  end
  it 'will log and raise a fatal exception' do
    expect { subject.process_node }.to raise_error(StandardError)
  end

  context 'with most typical configuration; adds a value to migrated data by default' do
    let(:config) do
      {
        'method' => 'ClassMethodRunnerClass.test_string_method',
        'field' => {
          'name' => field_name,
          'property' => field_property,
          'type' => 'Array'
        },
        'value' => 'blah'
      }
    end
    context 'using the basic class without overridden properties' do
      subject { ClassMethodRunnerClassBase.new(work_type, config) }
      it 'defaults to "always" adding migration data' do
        expect(subject.send(:value_add_to_migration)).to eq 'always'
      end
    end

    it 'will add data' do
      expect(subject.process_node(data)).to eq(work_type => { field_name => ['blah'] })
    end
    context 'with existing migration data for this field' do
      it 'will add data' do
        expect(subject.process_node(existing_data)).to eq(work_type => { field_name => %w(already_migrated_data blah) })
      end
    end
    context 'with existing duplicate migration data for this field' do
      let(:existing_data) { { work_type => { field_name => ['blah'] } } }
      it 'will not add duplicate data' do
        expect(subject.process_node(existing_data)).to eq(work_type => { field_name => %w(blah) })
      end
    end
    context 'with field type String' do
      let(:config) do
        {
          'method' => 'ClassMethodRunnerClass.test_string_method',
          'field' => {
            'name' => field_name,
            'property' => field_property,
            'type' => 'String'
          },
          'value' => 'blah'
        }
      end
      it 'will set a string data' do
        expect(subject.process_node(data)).to eq(work_type => { field_name => 'blah' })
      end
    end
  end

  context 'configured to consider if migrated data already exists for field' do
    let(:config) do
      {
        'method' => 'ClassMethodRunnerClass.test_string_method',
        'field' => {
          'name' => field_name,
          'property' => field_property,
          'type' => 'Array'
        },
        'value' => 'blah',
        'value_add_to_migration' => 'if_form_field_value_missing'
      }
    end
    it 'will add custom node data' do
      expect(subject.process_node(data)).to eq(work_type => { field_name => ['blah'] })
    end
    context 'with existing migration data for this field' do
      it 'will not add custom node data' do
        expect(subject.process_node(existing_data)).to eq(work_type => { field_name => ['already_migrated_data'] })
      end
    end
  end
  context 'configured to not add the value' do
    let(:config) do
      {
        'method' => 'ClassMethodRunnerClass.test_string_method',
        'field' => {
          'name' => field_name,
          'property' => field_property,
          'type' => 'Array'
        },
        'value' => 'blah',
        'value_add_to_migration' => 'never'
      }
    end
    it 'will not add custom node data' do
      expect(subject.process_node(data)).to eq(work_type => { field_name => [] })
    end
    context 'with existing migration data for this field' do
      it 'will not add custom node data' do
        expect(subject.process_node(existing_data)).to eq(work_type => { field_name => ['already_migrated_data'] })
      end
    end
  end
  context 'configured to add value to migration except for empty values' do
    let(:config) do
      {
        'method' => 'ClassMethodRunnerClass.test_string_method',
        'field' => {
          'name' => field_name,
          'property' => field_property,
          'type' => 'Array'
        },
        'value' => '',
        'value_add_to_migration' => 'except_empty_value'
      }
    end
    it 'will not add custom node data' do
      expect(subject.process_node(data)).not_to eq(work_type => { field_name => ['blah'] })
    end
  end
end
