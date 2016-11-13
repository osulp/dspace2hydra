require 'item'
require 'nokogiri'

RSpec.describe Item do
  subject { Item.new path }

  #path to the data directory for this "Item"
  let(:path) { File.join(File.dirname(__FILE__), "../../tmp/ITEM@1957-55523/data")}

  context "#initialize" do
    it "has a path" do
      expect(subject.path).to eq path
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
      expect(subject.metadata_xml.xpath("//metadata/value[@schema='dc'][@element='date']").length).to eq 3
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
      expect(subject.object_properties['otherIds'].length).to eq 2
      expect(subject.object_properties['otherIds']).to include "1957/1234"
      expect(subject.object_properties['otherIds']).to include "1957/5678"
      expect(subject.object_properties['otherIds']).not_to include "867/5309"
    end
  end
end