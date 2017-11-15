# frozen_string_literal: true
require 'rubygems'
require 'json'
require 'optparse'
require 'fileutils'
require 'date'
require 'logging'
require_relative '../lib/loggable'
require_relative '../lib/hydra_endpoint'
require 'yaml'
CONFIG = File.open(File.join(File.dirname(__FILE__), '../.config.yml')) { |f| YAML.safe_load(f) }

include Loggable

Logging.logger.root.level = :debug
@logger = Logging.logger[self]
Logging.logger.root.add_appenders(Logging.appenders.stdout(
                                    'stdout_brief_bright',
                                    layout: Loggable.stdout_brief_bright,
                                    level: :info
))
@logger = Logging.logger[self]

started_at = DateTime.now

options = {}
ARGV << '-h' if ARGV.empty?

OptionParser.new do |opts|
  opts.banner = 'Usage: batchProcess.rb [options]'

  opts.on('-j', '--json PATH', 'The full path to the json export from SOLR for works to publish. Expects JSON fields "response { docs [{id, has_model_ssim, workflow_state_name_ssim},...]}"') { |v| options['json'] = v }
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
end.parse!

raise 'Missing an argument. Try again.' if options['json'].nil?

file = File.read(options['json'])
data = JSON.parse(file)
works = data.dig('response', 'docs')

server = HydraEndpoint::Server.new(CONFIG['hydra_endpoint'], CONFIG, started_at)
works.each do |work|
  id = work.dig('id')
  model = work.dig('has_model_ssim').first
  state = work.dig('workflow_state_name_ssim').first
  @logger.info("Processing #{model} with id:#{id} from #{state}")
  server.advance_workflow(HydraEndpoint::Server::Response.new('id' => id))
end

puts 'Publishing works complete.'
