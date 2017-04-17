# frozen_string_literal: true
RSpec.describe Item do
  subject { Item.new path, config }

  # path to the data directory for this "Item"
  let(:path) { File.join(File.dirname(__FILE__), '../../fixtures/ITEM@1957-57239/data') }
  let(:config) { File.open(File.join(File.dirname(__FILE__), '../../fixtures/mocks/default.yml')) { |f| YAML.safe_load(f) } }

  context '#initialize' do
    it 'has a path' do
      expect(subject.path).to eq path
    end
  end

  context '#metadata' do
    it 'has built metadata' do
      expect(subject.metadata).to be_a_kind_of Hash
    end
  end

  context '#custom_metadata' do
    it 'has built custom_metadata' do
      expect(subject.custom_metadata).to be_a_kind_of Hash
    end
  end

  context '#metadata_xml' do
    it 'has a Nokogiri XML Document' do
      expect(subject.metadata_xml).to be_a_kind_of Nokogiri::XML::Document
    end
    it 'has a subject node' do
      expect(subject.metadata_xml.xpath("//metadata/value[@schema='dc'][@element='title']").length).to eq 1
    end
    it 'has a handle node' do
      expect(subject.metadata_xml.xpath("//metadata/value[@schema='dc'][@element='identifier'][@qualifier='uri']").length).to eq 1
    end
    it 'has three dates' do
      expect(subject.metadata_xml.xpath("//metadata/value[@schema='dc'][@element='date']").length).to eq 4
    end
  end

  context '#item_id' do
    it 'has an item_id' do
      expect(subject.item_id).to eq '1957-57239'
    end
  end

  context '#owner_id' do
    it 'has an owner_id' do
      expect(subject.owner_id).to eq '1957/43909'
    end
  end

  context '#other_ids' do
    it 'has an array of handles' do
      expect(subject.other_ids).to match_array( ['1957/4'] )
    end
  end

  context '#empty_other_ids' do
    subject { Item.new new_path, new_config }
    let(:new_path) { File.join(File.dirname(__FILE__), '../../fixtures/ITEM@1957-60170/data') }
    let(:new_config) { File.open(File.join(File.dirname(__FILE__), '../../fixtures/mocks/default.yml')) { |f| YAML.safe_load(f) } }
    it 'return empty array' do
      expect(subject.other_ids).to be_empty
    end
  end


  context '#collection_handles' do
    it 'has an array of handles' do
      expect(subject.collection_handles).to match_array( ['1957/43909', '1957/4'] )
    end
  end

  context '#object_properties' do
    it 'has an object_properties hash' do
      expect(subject.object_properties).to be_a_kind_of Hash
    end
    it 'has a bagType key with one value' do
      expect(subject.object_properties['bagType']).not_to be_nil
      expect(subject.object_properties['bagType'].length).to eq 1
    end
    it 'has an otherIds key with two values' do
      expect(subject.object_properties['otherIds']).not_to be_nil
      expect(subject.object_properties['otherIds'].length).to eq 1
      expect(subject.object_properties['otherIds']).to include '1957/4'
      expect(subject.object_properties['otherIds']).not_to include '867/5309'
    end
  end
end
