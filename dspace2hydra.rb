require 'yaml'
require 'optparse'
require_relative 'lib/item'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: dspace2hydra.rb [options]'

  opts.on('-i', '--item PATH', 'The Dspace ITEM path to process.') { |v| options[:item_path] = v }

  opts.on('-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end.parse!

config = YAML::load_file(File.join(File.dirname(File.expand_path(__FILE__)), '.config.yml')) || {}
config.merge!(options)

raise 'Missing ITEM path.' if config[:item_path].nil?

@item = Item.new(config[:item_path])
puts @item.object_properties
