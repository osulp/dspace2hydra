# frozen_string_literal: true
RSpec.describe Mapping::Extensions::Cacheable do
  let(:klass) do
    Class.new do
      extend Mapping::Extensions::Cacheable
      Mapping::Extensions::Cacheable::CACHE_DIRECTORY = '../../../spec/cache'
    end
  end
  let(:item) { described_class::Item.new('id', 'value', 'label', 'uri') }

  it 'returns an default CACHED_CLASSES' do
    expect(described_class::CACHED_CLASSES).to eq [described_class::Item, Symbol]
  end

  it 'returns an Item struct' do
    expect(item.id).to eq 'id'
    expect(item.label).to eq 'label'
    expect(item.value).to eq 'value'
    expect(item.uri).to eq 'uri'
  end

  context 'with a cache file' do
    let(:filename) { 'cacheable_spec.yml' }
    before :each do
      begin
        File.unlink(File.join(File.dirname(__FILE__), '../../../cache/', filename))
      rescue
      end
    end

    it 'can add to the cache' do
      expect(klass.add_to_cache(item, filename)).to eq item
    end

    it 'can search the cache' do
      klass.add_to_cache(item, filename)
      expect(klass.search_cache('label', :label, filename)).to eq item
    end
  end
end
