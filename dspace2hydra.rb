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

#TODO: Show data before it loads?
pp data
exit

he = HydraEndpoint.new(CONFIG['hydra_endpoint'])
login_page = he.login
#pp login_page

#
new_work_page = he.new_work

upload_page = he.upload he.new_work_form(new_work_page), bags.first.files.first.file
json = JSON.parse upload_page.body
file_ids = json["files"].map { |f| f["id"] }
#file_ids needs to be added to new_work POST so that the files are associated with the new work?
#pp upload_page
#pp new_work_page

submitted_page = he.submit_new_work new_work_page, data, file_ids
pp submitted_page

