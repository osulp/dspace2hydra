require 'bag'
require 'item'

RSpec.describe Bag do
  subject { Bag.new(path) }
  let(:path) { File.join(File.dirname(__FILE__), "../../tmp/ITEM@1957-55523") }

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

  it "has #data_paths" do
    expect(subject.data_paths.length).to be_truthy
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
    end
  end
end