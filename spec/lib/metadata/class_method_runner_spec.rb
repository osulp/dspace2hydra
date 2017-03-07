# frozen_string_literal: true
class ClassMethodRunnerClass
  include Metadata::ClassMethodRunner
  def initialize(work_type, config = {})
    @config = config
    @work_type = work_type
  end

  def self.test_string_method(value, *_args)
    value
  end
end

RSpec.describe Metadata::ClassMethodRunner do
  subject { ClassMethodRunnerClass.new(work_type, config) }
  let(:work_type) { 'blah_work' }
  let(:form_field) { "%{work_type}['%{form_field_name}'][]" }
  let(:field_name) { 'some_field_name' }
  let(:form_field_name) { format(form_field, work_type: work_type, form_field_name: field_name) }
  let(:data) { {} }

  context 'with most typical configuration; adds a value to migrated data by default' do
    let(:config) do
      {
        'method' => 'ClassMethodRunnerClass.test_string_method',
        'form_field' => form_field,
        'form_field_name' => field_name,
        'value' => 'blah'
      }
    end
    it 'will add data' do
      expect(subject.process_node(data)).to eq(form_field_name.to_s => ['blah'])
    end
    context 'with existing migration data for this field' do
      let(:data) { { form_field_name.to_s => ['already_migrated_data'] } }
      it 'will add data' do
        expect(subject.process_node(data)).to eq(form_field_name.to_s => %w(already_migrated_data blah))
      end
    end
  end

  context 'configured to consider if migrated data already exists for field' do
    let(:config) do
      {
        'method' => 'ClassMethodRunnerClass.test_string_method',
        'form_field' => form_field,
        'form_field_name' => field_name,
        'value' => 'blah',
        'add_to_migration' => 'if_field_value_missing'
      }
    end
    it 'will add custom node data' do
      expect(subject.process_node(data)).to eq(form_field_name.to_s => ['blah'])
    end
    context 'with existing migration data for this field' do
      let(:data) { { form_field_name.to_s => ['already_migrated_data'] } }
      it 'will not add custom node data' do
        expect(subject.process_node(data)).to eq(form_field_name.to_s => ['already_migrated_data'])
      end
    end
  end
  context 'configured to not add the value' do
    let(:config) do
      {
        'method' => 'ClassMethodRunnerClass.test_string_method',
        'form_field' => form_field,
        'form_field_name' => field_name,
        'value' => 'blah',
        'add_to_migration' => 'never'
      }
    end
    it 'will not add custom node data' do
      expect(subject.process_node(data)).to eq(form_field_name.to_s => [])
    end
    context 'with existing migration data for this field' do
      let(:data) { { form_field_name.to_s => ['already_migrated_data'] } }
      it 'will not add custom node data' do
        expect(subject.process_node(data)).to eq(form_field_name.to_s => ['already_migrated_data'])
      end
    end
  end
end
