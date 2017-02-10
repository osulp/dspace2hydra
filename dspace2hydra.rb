require 'optparse'
require 'pathname'
require 'json'
require 'yaml'
require_relative 'lib/bag'
require_relative 'lib/hydra_endpoint'
require_relative 'mapping/mapping'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: dspace2hydra.rb [options]'

  opts.on('-b', '--bag PATH', 'The Dspace bag path to process.') { |v| options['bag_path'] = v }
  opts.on('-c', '--config PATH', 'The Item config path for each bag.') { |v| options['mapping_config'] = v }
  opts.on('-d', '--directory PATH', 'The directory path containing bags to bulk process.') { |v| options['bags_directory'] = v }
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
end.parse!

CONFIG.merge!(options)
raise 'Missing BAG path or BAGS directory.' if CONFIG['bag_path'].nil? && CONFIG['bags_directory'].nil?
raise 'Missing BAG mapping config.' if CONFIG['mapping_config'].nil?

bags = []
mapping_config = File.open(File.join(File.dirname(__FILE__), CONFIG['mapping_config'])) { |f| YAML.load(f) }

if CONFIG['bags_directory']
  # process each bag sub-directory
  Pathname.new(CONFIG['bags_directory']).children.select do |bag_path|
    bags << Bag.new(bag_path, mapping_config) if bag_path.directory?
  end
else
  bags << Bag.new(CONFIG['bag_path'], mapping_config)
end

## Testing loading one bag
data = {}
bags.first.item.metadata.each do |k, nodes|
  nodes.each do |metadata_node|
    data = metadata_node.process_node(data)
  end
end
bags.first.item.custom_metadata.each do |k, nodes|
  nodes.each do |custom_metadata_node|
    data = custom_metadata_node.process_node(data)
  end
end

#TODO: Show data before it loads?
#pp data
#exit

he = HydraEndpoint.new(CONFIG['hydra_endpoint'])

file_ids  = []
bags.first.files.each do |item_file|
  # Make a temporary copy of the file with the proper filename, upload it, grab the file_id from the servers response
  # and remove the temporary file
  item_file.copy_to_metadata_full_path
  upload_response = he.upload(item_file.file(item_file.metadata_full_path))
  json = JSON.parse(upload_response.body)
  file_ids << json["files"].map { |f| f["id"] }
  item_file.delete_metadata_full_path
end
file_ids.flatten!.uniq!

submitted_page = he.submit_new_work data, file_ids
pp submitted_page

