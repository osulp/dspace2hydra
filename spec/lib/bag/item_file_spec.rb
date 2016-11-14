RSpec.describe ItemFile do
  subject { ItemFile.new full_path }

  #path to the for this "File"
  let(:full_path) { File.join(File.dirname(__FILE__), "../../../tmp/bags/ITEM@1957-55523/data/ORIGINAL/1")}

  it "has a full_path" do
    expect(subject.full_path).to eq full_path
  end

  it 'has a description' do
    expect(subject.description).not_to be_nil
  end

  it 'has a source' do
    expect(subject.source).not_to be_nil
  end

  it 'has a sequence_id' do
    expect(subject.sequence_id).not_to be_nil
  end
  it 'has a name' do
    expect(subject.name).not_to be_nil
  end
  context "#metadata_xml" do
    it "has a Nokogiri XML Document" do
      expect(subject.metadata_xml).to be_a_kind_of Nokogiri::XML::Document
    end
    it "has a name node" do
      expect(subject.metadata_xml.xpath("//metadata/value[@name='name']").length).to eq 1
    end
    it "has a source node" do
      expect(subject.metadata_xml.xpath("//metadata/value[@name='source']").length).to eq 1
    end
    it "has a description node" do
      expect(subject.metadata_xml.xpath("//metadata/value[@name='description']").length).to eq 1
    end
    it "has a sequence_id node" do
      expect(subject.metadata_xml.xpath("//metadata/value[@name='sequence_id']").length).to eq 1
    end
  end

end