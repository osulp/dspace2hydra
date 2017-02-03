RSpec.describe Mapping::Subject do
  let(:query) { "Giant panda--Breeding" }
  let(:uri) { "http://id.loc.gov/authorities/subjects/sh2010005839" }
  let(:mock_response) { File.readlines(File.join(File.dirname(__FILE__), '../fixtures/mocks/sh2010005839.json')).join }
  let(:cache_file_override) { "tmp/bogus_cache" }
  it '#self.uri' do
    expect(described_class.respond_to?(:uri)).to be_truthy
  end

  context "when searching for a URI" do
    it 'returns a uri' do
      stub_const("Mapping::Subject::LCSH_CACHE_FILE", cache_file_override)
      stub_request(:get, "http://id.loc.gov/search/?format=json&q=http://id.loc.gov/authorities/subjects")
        .to_return(:status => 200, :body => mock_response, :headers => {})
      allow(Mapping::Subject).to receive(:search_cache).and_return(nil)
      allow(Mapping::Subject).to receive(:add_to_cache).and_return(nil)
      expect(described_class.uri(query)).to eq uri
    end
  end
end
