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
require_relative 'lib/work'
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
# @param [Boolean] error - error level
def create_log_file_appender(date_string, error = false)
  log_type_string = error ? 'error.' : ''
  log_file = File.join(File.dirname(__FILE__), 'log', "#{date_string}.#{log_type_string}log")
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

##
# Publish the work to the server
# @param [Hash] data - the processed data to publish to the server
# @param [HydraEndpoint] server - the endpoint to publish the work to
def publish_work(data, server)
  @logger.info('Publishing work to server')
  page = server.publish_work(data)
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
type_config['admin_set_id'] = CONFIG['admin_set_id'] unless CONFIG['admin_set_id'].nil?

@logger = Logging.logger[self]

# Determine if a cached json file is being reprocessed or a new number of bags
if CONFIG['cached_json']
  server = HydraEndpoint::Server.new(CONFIG['hydra_endpoint'], type_config, started_at)
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
      server = HydraEndpoint::Server.new(CONFIG['hydra_endpoint'], type_config, started_at)

      # We've decided that if a work has 2+ files, then it should be a Parent work with each file being a
      # child.
      if bag.files_for_upload.count > 1
        work = Work::MigrationStrategy::ParentWithChildren.new(bag, server, CONFIG, type_config)
      else
        work = Work::MigrationStrategy::SingleWork.new(bag, server, CONFIG, type_config)
      end
      work.process_bag

      @logger.info("Finished in #{time_since(bag_start)}")
    rescue StandardError => e
      @logger.fatal("#{e.message} : #{e.backtrace.join("\n\t")}")
    ensure
      stop_logging_to(item_log_path(bag, started_at), item_id: item_id)
    end
  end
  @logger.info("DSpace2Hydra finished processing bags in #{time_since(started_at)}")
end
################################################################################
