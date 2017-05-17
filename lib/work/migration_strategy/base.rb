# frozen_string_literal: true
module Work
  module MigrationStrategy
    class Base
      include Loggable

      def initialize(bag, server, config, work_type_config)
        @logger = Logging.logger[self]
        @bag = bag
        @server = server
        @config = config
        @work_type_config = work_type_config
        @work_type = work_type_config['work_type']
        @work_type_node = Metadata::WorkTypeNode.new(@work_type_config, @config)
      end

      private

      ##
      # Advance the work through its workflow, typically to the 'deposited' state
      # @param [Hash] response - the work response from the server after the new work was created
      # @param [HydraEndpoint] server - the endpoint to advance the work on
      # @return [HydraEndpoint::Server::Response] - the response from the server
      def advance_workflow(response, server)
        @logger.info('Advancing work through workflow')
        server.advance_workflow(response)
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

      def set_deep_field_property(data, value, *fields)
        if fields.count == 1
          data[fields[0]] = value
        else
          field = fields.shift
          data[field] = {} unless data[field]
          set_deep_field_property(data[field], value, *fields)
        end
        data
       end
    end
  end
end
