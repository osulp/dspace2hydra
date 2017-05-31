# frozen_string_literal: true
require_relative 'nested_configuration'
require_relative 'loggable'
require_relative 'metadata/work_type_node'
require_relative 'work/migration_strategy/base'

# require all of the migration strategies
Dir[File.join(File.dirname(__FILE__), 'work/migration_strategy/*.rb')].each do |file|
  require file unless file == __FILE__
end
