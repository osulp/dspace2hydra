RSpec.describe Item do
  subject { Item.new path, config }

  #path to the data directory for this "Item"
  let(:path) { File.join(File.dirname(__FILE__), "../../fixtures/ITEM@1957-57239/data") }
  let(:config) { File.open(File.join(File.dirname(__FILE__), "../../fixtures/mocks/default.yml")) { |f| YAML.load(f) } }

  context "#initialize" do
    it "has a path" do
      expect(subject.path).to eq path
    end
  end

  context "#metadata" do
    it "has built metadata" do
      expect(subject.metadata).to be_a_kind_of Hash
    end
  end

  context "#custom_metadata" do
    it "has built custom_metadata" do
      expect(subject.custom_metadata).to be_a_kind_of Hash
    end
  end

  context "#metadata_xml" do
    it "has a Nokogiri XML Document" do
      expect(subject.metadata_xml).to be_a_kind_of Nokogiri::XML::Document
    end
    it "has a subject node" do
      expect(subject.metadata_xml.xpath("//metadata/value[@schema='dc'][@element='title']").length).to eq 1
    end
    it "has a handle node" do
      expect(subject.metadata_xml.xpath("//metadata/value[@schema='dc'][@element='identifier'][@qualifier='uri']").length).to eq 1
    end
    it "has three dates" do
      expect(subject.metadata_xml.xpath("//metadata/value[@schema='dc'][@element='date']").length).to eq 4
    end
  end

  context "#object_properties" do
    it "has an object_properties hash" do
      expect(subject.object_properties).to be_a_kind_of Hash
    end
    it "has a bagType key with one value" do
      expect(subject.object_properties['bagType']).not_to be_nil
      expect(subject.object_properties['bagType'].length).to eq 1
    end
    it "has an otherIds key with two values" do
      expect(subject.object_properties['otherIds']).not_to be_nil
      expect(subject.object_properties['otherIds'].length).to eq 1
      expect(subject.object_properties['otherIds']).to include "1957/4"
      expect(subject.object_properties['otherIds']).not_to include "867/5309"
    end
  end
end