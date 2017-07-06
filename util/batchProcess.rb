# frozen_string_literal: true
require 'rubygems'
require 'csv'
require 'optparse'
require 'fileutils'
require 'zip'

UPDATE_SPREADSHEET = true

started_at = DateTime.now

options = {}
ARGV << '-h' if ARGV.empty?

OptionParser.new do |opts|
  opts.banner = 'Usage: batchProcess.rb [options]'

  opts.on('-p', '--spreadsheet PATH', 'The full path to the master spreadsheet to process.') { |v| options['spreadsheet'] = v }
  opts.on('-c', '--count NUM', 'The number of bags to process.') { |v| options['count'] = v }
  opts.on('-a', '--archives-directory PATH', 'The full path to the archives directory to store bags as they are processed.') { |v| options['archives_directory'] = v }
  opts.on('-s', '--source-directory PATH', 'The full path to the source directory of the bags to process.') { |v| options['source_directory'] = v }
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
end.parse!

if options['spreadsheet'].nil? || options['count'].nil? || options['archives_directory'].nil? || options['source_directory'].nil?
  raise 'Missing an argument. Try again.'
end

def zip_files_exist?(grouped_bags, options)
  missing_files = []
  grouped_bags.each_key do |key|
    grouped_bags[key].each do |group|
      file = group['bag_file']
      missing_files << file unless File.exist?(File.join(options['source_directory'], file))
    end
  end
  missing_files.each { |f| puts "Missing #{f}" }
  missing_files.empty?
end

#TODO : Move this to its own configuration file
work_type_configs = {
  'Administrative Report or Publication' => 'administrative_report_or_publication.yml',
  'Conference Proceedings or Journal' => 'conference_proceeding_or_journal.yml',
  'Dataset' => 'datasets.yml',
  'Default' => 'default.yml',
  'Faculty Article - OA Policy Implementation' => 'article.yml',
  'Graduate Project' => 'graduate_project.yml',
  'Graduate Thesis or Dissertation' => 'graduate_thesis_or_dissertation.yml',
  'Open Educational resource' => 'open_educational_resource.yml',
  'Technical Report' => 'technical_report.yml',
  'Undergraduate Thesis or Project' => 'undergraduate_thesis_or_project.yml'
}
started_at_directory = File.join(options['archives_directory'], started_at.strftime('%Y%m%d%H%M%S'))
started_at_path = File.join(started_at_directory)
raise "#{started_at_path} already exists, cannot proceed with processing." if Dir.exist?(started_at_path)
Dir.mkdir(started_at_path) unless Dir.exist?(started_at_path)

open(options['spreadsheet'], 'r') do |original|
  open("#{options['spreadsheet']}.tmp", 'w') do |tmp|
    open(File.join(started_at_path, 'bags.csv'), 'w') do |new|
      original.each do |line|
        tmp.write(line) if original.lineno === 1
        new.write(line) if original.lineno === 1
        tmp.write(line) if original.lineno > options['count'].to_i + 1 && original.lineno != 1
        new.write(line) if original.lineno <= options['count'].to_i + 1 && original.lineno != 1
      end
    end
  end
end

commands = []
csv = CSV.read(File.join(started_at_path, 'bags.csv'), headers: true, encoding: 'UTF-8').map(&:to_hash)
bags_with_config = csv.map { |c| c.merge('config' => work_type_configs[c['admin_set_name']]) }
grouped_bags = bags_with_config.group_by { |h| h['config'] }

if(zip_files_exist?(grouped_bags, options))

  grouped_bags.each_key do |key|
    config_dir = File.join(started_at_path, key.gsub(/\.yml$/, ''))
    Dir.mkdir(config_dir)
    # Now unzip each bag from its original directory into the config_dir
    grouped_bags[key].each do |group|
      Dir.mkdir(File.join(config_dir, group['bag_file'].gsub(/\.zip/, '')))
      Zip::File.open(File.join(options['source_directory'], group['bag_file'])) do |zip_file|
        zip_file.each do |f|
          fpath = File.join(config_dir, f.name)
          FileUtils.mkdir_p(File.dirname(fpath))
          zip_file.extract(f, fpath) unless File.exist?(fpath)
        end
      end
    end
    commands << "dspace2hydra.rb -d #{File.expand_path(config_dir)} -c config/#{key}"
  end

  FileUtils.mv("#{options['spreadsheet']}.tmp", (options['spreadsheet']).to_s) if UPDATE_SPREADSHEET

  puts "Batch processing of #{options['count']} bags complete, the following commands will migrate each of the prepared directories."
  commands.each { |c| puts c }
end
