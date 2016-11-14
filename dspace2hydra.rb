require 'optparse'
require 'pathname'
require 'json'
require_relative 'lib/bag'
require_relative 'lib/hydra_endpoint'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: dspace2hydra.rb [options]'

  opts.on('-b', '--bag PATH', 'The Dspace bag path to process.') { |v| options['bag_path'] = v }
  opts.on('-d', '--directory PATH', 'The directory path containing bags to bulk process.') { |v| options['bags_directory'] = v }
  opts.on('-t', '--type STRING', 'The Item type for each bag. (ie. "etd")') { |v| options['bag_type'] = v }
  opts.on('-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end.parse!

CONFIG.merge!(options)
raise 'Missing BAG path or BAGS directory.' if CONFIG['bag_path'].nil? && CONFIG['bags_directory'].nil?
raise 'Missing BAG type.' if CONFIG['bag_type'].nil?

bags = []

if CONFIG['bags_directory']
  # process each bag sub-directory
  Pathname.new(CONFIG['bags_directory']).children.select do |bag_path|
    bags << Bag.new(bag_path, CONFIG['bag_type']) if bag_path.directory?
  end
else
  bags << Bag.new(CONFIG['bag_path'], CONFIG['bag_type'])
end

## Testing loading one bag
data = {}
bags.first.item.metadata.each do |k, nodes|
  nodes.each do |metadata_node|
    data[metadata_node.form_field] ||= []
    data[metadata_node.form_field] << metadata_node.content
    #puts "#{bags.first.path} => metadata for #{k} : qualifier type #{metadata_node.qualifier.type} => form field #{metadata_node.form_field} => content: #{metadata_node.content}"
  end
end

#TODO: Show data before it loads?
pp data


he = HydraEndpoint.new(CONFIG['hydra_endpoint'])
login_page = he.login
#pp login_page

new_work_page = he.new_work
submitted_page = he.submit_new_work new_work_page, data
pp submitted_page

#
#upload_page = he.upload he.new_work_form(new_work_page), bags.first.files.first.file
#json = JSON.parse upload_page.body
#file_ids = json["files"].map { |f| f["id"] }
#file_ids needs to be added to new_work POST so that the files are associated with the new work?
#pp upload_page
#pp new_work_page
