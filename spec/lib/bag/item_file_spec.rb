RSpec.describe ItemFile do
  subject { ItemFile.new full_path }

  #path to the for this "File"
  let(:full_path) { File.join(File.dirname(__FILE__), "../../fixtures/ITEM@1957-57239/data/ORIGINAL/6")}
  let(:metadata_full_path) { File.join(File.dirname(__FILE__), "../../fixtures/ITEM@1957-57239/data/ORIGINAL/VanTuyl-Whitmire-PLOSOne-Final.pdf")}

  it "has a file" do
    expect(subject.file).to be_a_kind_of File
  end

  it "has a parent directory" do
    expect(subject.parent_directory).to eq("ORIGINAL")
  end

  it "has a metadata_full_path" do
    expect(subject.metadata_full_path).to eq metadata_full_path
  end

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

  it 'copies and deletes a temporary metadata file with proper name' do
    subject.copy_to_metadata_full_path
    expect(File.exists?(metadata_full_path)).to be_truthy
    subject.delete_metadata_full_path
    expect(File.exists?(metadata_full_path)).to be_falsey
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