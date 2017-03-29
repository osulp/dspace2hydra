# frozen_string_literal: true
require 'optparse'
require 'pathname'
require 'json'
require 'yaml'
require_relative 'lib/bag'
require_relative 'lib/hydra_endpoint'
require_relative 'mapping/mapping'

options = {}
ARGV << '-h' if ARGV.empty?

OptionParser.new do |opts|
  opts.banner = 'Usage: dspace2hydra.rb [options]'

  opts.on('-a', '--admin_set_id ID', 'The Hyrax AdminSet ID to associate this work to.') { |v| options['admin_set_id'] = v }
  opts.on('-b', '--bag PATH', 'The Dspace bag path to process.') { |v| options['bag_path'] = v }
  opts.on('-c', '--config PATH', 'The Item type config path for each bag.') { |v| options['type_config'] = v }
  opts.on('-d', '--directory PATH', 'The directory path containing bags to bulk process.') { |v| options['bags_directory'] = v }
  opts.on('-j', '--cached_json PATH', 'Post the json file directly to the server.') { |v| options['cached_json'] = v }
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
end.parse!
CONFIG.merge!(options)

def validate_arguments(config)
  if config['cached_json'].nil?
    raise 'Missing BAG path or BAGS directory.' if CONFIG['bag_path'].nil? && CONFIG['bags_directory'].nil?
  end
  raise 'Missing BAG type config.' if CONFIG['type_config'].nil?
  true
end

# Process the metadata, and upload the files for a bag
# @param [Bag] bag - the bag to process
# @param [HydraEndpoint] server - the server to submit a work and upload files to
def process_bag(bag, server)
  data = process_bag_metadata(bag)
  file_ids = upload_files(bag, server)
  data[bag.uploaded_files_field_name] = bag.uploaded_files_field(file_ids)
  page = server.submit_new_work(bag, data)
end

def publish_work(data, server)
  page = server.publish_work(data)
end

def advance_workflow(response, server)
  page = server.advance_workflow(response)
end

##
# Process the mapped as well as the custom metadata configured for this bag.
# @param [Bag] bag - the bag to process
# @return [Hash] - the processed metadata hash
def process_bag_metadata(bag)
  data = {}
  bag.item.metadata.each do |_k, nodes|
    nodes.each do |metadata_node|
      data = metadata_node.qualifier.process_node(data)
    end
  end
  bag.item.custom_metadata.each do |_k, nodes|
    nodes.each do |custom_metadata_node|
      data = custom_metadata_node.process_node(data)
    end
  end
  data
end

##
# Upload the files for this bag, and return the list of file_ids that were generated
# through the process.
# @param [Bag] bag - the bag to process
# @param [HydraEndpoint] server - the server to upload files to
# @return [Array] - an array of file_id's that were generated on the server
def upload_files(bag, server)
  file_ids = []
  bag.files_for_upload.each do |item_file|
    # Make a temporary copy of the file with the proper filename, upload it, grab the file_id from the servers response
    # and remove the temporary file
    item_file.copy_to_metadata_full_path
    upload_response = server.upload(item_file.file(item_file.metadata_full_path))
    json = JSON.parse(upload_response.body)
    file_ids << json['files'].map { |f| f['id'] }
    item_file.delete_metadata_full_path
  end
  file_ids.flatten.uniq
end

validate_arguments(CONFIG)

type_config = File.open(File.join(File.dirname(__FILE__), CONFIG['type_config'])) { |f| YAML.safe_load(f) }
# Overwrite the [TYPE_CONFIG].admin_set_id configuration if there was one passed on the commandline
type_config['admin_set_id'] = CONFIG['admin_set_id'] unless CONFIG['admin_set_id'].nil?

started_at = DateTime.now
server = HydraEndpoint.new(CONFIG['hydra_endpoint'], type_config, started_at)

## Testing processing and loading one bag
if CONFIG['cached_json']
  file = File.open(File.join(File.dirname(__FILE__), CONFIG['cached_json']))
  json = file.read
  data = JSON.parse(json)
  work = publish_work(data, server)
  work = advance_workflow(work, server) if server.should_advance_work?
  pp work
else
  bags = []
  if CONFIG['bags_directory']
    # process each bag sub-directory
    Pathname.new(CONFIG['bags_directory']).children.select do |bag_path|
      bags << Bag.new(bag_path, CONFIG, type_config) if bag_path.directory?
    end
  else
    bags << Bag.new(CONFIG['bag_path'], CONFIG, type_config)
  end

  bag = bags.first
  work = process_bag(bag, server)
  work = advance_workflow(work, server) if server.should_advance_work?
  server.clear_csrf_token
end
#########################################
