RSpec.describe Bag do
  subject { Bag.new(path, application_config, type_config) }
  let(:path) { File.join(File.dirname(__FILE__), "../../fixtures/ITEM@1957-57239") }
  let(:type_config) { File.open(File.join(File.dirname(__FILE__), "../../fixtures/mocks/default.yml")) { |f| YAML.load(f) } }
  let(:application_config) { File.open(File.join(File.dirname(__FILE__), "../../fixtures/mocks/application.yml")) { |f| YAML.load(f) } }

  context "#initialize" do
    it "has a path" do
      expect(subject.path).to eq(path)
    end
  end

  context "#bagit" do
    it "has a bagit" do
      expect(subject.bagit).not_to be_nil
    end
    it "has lines of text" do
      expect(subject.bagit.length).to be_between 1, 100
    end
  end

  context "#manifest" do
    it "has a manifest hash" do
      expect(subject.manifest).not_to be_nil
      expect(subject.manifest).to be_a_kind_of Hash
    end
    it "has metadata.xml and object.properties keys" do
      expect(subject.manifest.keys).to include "data/metadata.xml"
      expect(subject.manifest.keys).to include "data/object.properties"
    end
  end

  it "has an #item" do
    expect(subject.item).not_to be_nil
    expect(subject.item).to be_a_kind_of Item
  end

  it "has data_paths" do
    expect(subject.data_paths.length).to be_truthy
  end

  it "has a #type_config" do
    expect(subject.type_config).to eq type_config
  end

  it "has a #uploaded_files_field_name" do
    expect(subject.uploaded_files_field_name).to eq format(type_config['uploaded_files']['field']['property'], field_name: type_config['uploaded_files']['field']['name'])
  end

  it 'has a flattened array for uploaded_files_field' do
    expect(subject.uploaded_files_field([0,[1,2,3,4]])).to eq [0,1,2,3,4]
  end

  it "has a files_for_upload" do
    expect(subject.files_for_upload.length).to eq 1
  end

  context "without data_paths" do
    it "does not have data_paths" do
      allow(subject).to receive(:manifest) { { "metadata.xml": "", "object.properties": "" } }
      expect(subject.data_paths).to eq []
    end
  end

  context "having files" do
    it "has a list of files" do
      expect(subject.files.length).to be_truthy
      subject.files.each do |f|
        expect(f).to be_a_kind_of ItemFile
      end
    end

    it "has an ordered sequence of files" do
      expect(subject.files.map { |f| f.sequence_id }).to eq ["2", "3", "6"]
    end
  end
end
