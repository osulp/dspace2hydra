# frozen_string_literal: true
require 'optparse'
require 'pathname'
require 'json'
require 'yaml'
require 'logging'
require_relative 'lib/loggable'
require_relative 'lib/timeable'
require_relative 'lib/bag'
require_relative 'lib/hydra_endpoint'
require_relative 'mapping/mapping'

include Loggable
include Timeable

started_at = DateTime.now

Logging.logger.root.level = :debug
@logger = Logging.logger[self]
Logging.logger.root.add_appenders(Logging.appenders.stdout(
                                    'stdout_brief_bright',
                                    layout: Loggable.stdout_brief_bright,
                                    level: :info
))

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

##
# Create a standard or error based log file appender and add it to the root logger
# @param [String] date_string - the datetime string to name the file
# @param [Boolean] error - whether or not it's an error log (default false)
def create_log_file_appender(date_string, error = false)
  error_string = error ? 'error.' : ''
  log_file = File.join(File.dirname(__FILE__), 'log', "#{date_string}.#{error_string}log")
  appender = Logging.appenders.file(log_file, layout: Loggable.basic_layout)
  appender = Logging.appenders.file(log_file, layout: Loggable.basic_layout, level: :error) if error
  Logging.logger.root.add_appenders(log_file, appender)
end

##
# Validate if the configuration has the appropriate arguments for any specific type of execution
# @param [Hash] config - the configuration hash to inspect
# @return [Boolean] - true if no exceptions were raised
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
  @logger.info('Processing bag')
  data = process_bag_metadata(bag)
  file_ids = upload_files(bag, server)
  data[bag.uploaded_files_field_name] = bag.uploaded_files_field(file_ids)
  page = server.submit_new_work(bag, data)
end

##
# Publish the work to the server
# @param [Hash] data - the processed data to publish to the server
# @param [HydraEndpoint] server - the endpoint to publish the work to
def publish_work(data, server)
  @logger.info('Publishing work to server')
  page = server.publish_work(data)
end

##
# Advance the work through its workflow, typically to the 'deposited' state
# @param [Hash] response - the work response from the server after the new work was created
# @param [HydraEndpoint] server - the endpoint to advance the work on
def advance_workflow(response, server)
  @logger.info('Advancing work through workflow')
  page = server.advance_workflow(response)
end

##
# Process the mapped as well as the custom metadata configured for this bag.
# @param [Bag] bag - the bag to process
# @return [Hash] - the processed metadata hash
def process_bag_metadata(bag)
  data = {}
  @logger.info('Mapping item metadata')
  bag.item.metadata.each do |_k, nodes|
    nodes.each do |metadata_node|
      data = metadata_node.qualifier.process_node(data)
    end
  end
  @logger.info('Mapping configured custom metadata')
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
    @logger.info("Uploading filename from metadata to server: #{item_file.metadata_full_path}")
    upload_response = server.upload(item_file.file(item_file.metadata_full_path))
    json = JSON.parse(upload_response.body)
    file_ids << json['files'].map { |f| f['id'] }
    item_file.delete_metadata_full_path
  end
  file_ids.flatten.uniq
end

##
# Build the item's log file path
# @param [Metadata::Bag] bag - the bag being operated on
# @param [DateTime] started_at - the datetime of this execution helps to keep log file names unique and meaningful
def item_log_path(bag, started_at)
  item_cache_path = File.join(File.dirname(__FILE__), "#{CONFIG['cache_and_logging_path']}/ITEM@#{bag.item.item_id}")
  timestamp = started_at.strftime('%Y%m%d%H%M%S')
  File.join(item_cache_path, "#{timestamp}.log")
end

################################################################################

create_log_file_appender(started_at.strftime('%Y%m%d%H%M%S'))
create_log_file_appender(started_at.strftime('%Y%m%d%H%M%S'), error: true)
validate_arguments(CONFIG)

type_config = File.open(File.join(File.dirname(__FILE__), CONFIG['type_config'])) { |f| YAML.safe_load(f) }
# Overwrite the [TYPE_CONFIG].admin_set_id configuration if there was one passed on the commandline
type_config['admin_set_id'] = CONFIG['admin_set_id'] unless CONFIG['admin_set_id'].nil?

@logger = Logging.logger[self]

# Determine if a cached json file is being reprocessed or a new number of bags
if CONFIG['cached_json']
  server = HydraEndpoint.new(CONFIG['hydra_endpoint'], type_config, started_at)
  file = File.open(File.join(File.dirname(__FILE__), CONFIG['cached_json']))
  json = file.read
  data = JSON.parse(json)
  work = publish_work(data, server)
  work = advance_workflow(work, server) if server.should_advance_work?
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

  @logger.info('DSpace2Hydra started processing bags.')

  # Process all of the bags individually
  bags.each do |bag|
    item_id = "ITEM@#{bag.item.item_id}"
    begin
      bag_start = DateTime.now
      start_logging_to(item_log_path(bag, started_at), item_id: item_id)
      @logger.info('Started')
      server = HydraEndpoint.new(CONFIG['hydra_endpoint'], type_config, started_at)
      work = process_bag(bag, server)
      @logger.warn('Not configured to advance work through workflow') unless server.should_advance_work?
      work = advance_workflow(work, server) if server.should_advance_work?
      server.clear_csrf_token
      @logger.info("Finished in #{time_since(bag_start)}")
    rescue StandardError => e
      @logger.fatal(e.message)
    ensure
      stop_logging_to(item_log_path(bag, started_at), item_id: item_id)
    end
  end
  @logger.info("DSpace2Hydra finished processing bags in #{time_since(started_at)}")
end
################################################################################
