# frozen_string_literal: true
RSpec.describe Mapping::Extensions::LocSearchable do
  let(:klass) do
    Class.new do
      extend Mapping::Extensions::LocSearchable
      include Loggable
      @logger = Logging.logger[self]
    end
  end

  let(:json) { File.read(File.join(File.dirname(__FILE__), '../../../fixtures/mocks/plywood.json')) }
  let(:content_source) { 'http://id.loc.gov/authorities/subject' }

  it 'parses items' do
    expect(klass.parse_items(json).count).to eq 20
  end

  context 'when searching LOC' do
    it 'logs a warning and returns bogus item when there are no parsed items' do
      stub_request(:get, 'http://id.loc.gov/search/?format=json&q=http://id.loc.gov/authorities/subject')
        .to_return(status: 200, body: json, headers: {})
      allow(klass).to receive(:parse_items) { {} }
      expect(klass.search_loc(content_source, 'plywood')).to eq(id: 'plywood', label: 'plywood', uri: 'plywood')
    end
    it 'logs a warning and returns a bogus item when where are no found items' do
      stub_request(:get, 'http://id.loc.gov/search/?format=json&q=http://id.loc.gov/authorities/subject')
        .to_return(status: 200, body: json, headers: {})
      allow(klass).to receive(:parse_items) { [{ id: 'blah', label: 'not-plywood' }] }
      expect(klass.search_loc(content_source, 'plywood')).to eq(id: 'plywood', label: 'plywood', uri: 'plywood')
    end
  end
end
