# frozen_string_literal: true
module Work
  module MigrationStrategy
    class SingleWork < Base
      include Loggable

      ##
      # Creates a single work for the migrated bag. All of the metadata is published along with each file that is
      # uploaded and associated to the work. This is a basic/standard migrated item.
      def process_bag
        log_to_summary('----------------------------------------------------------------------------------')
        log_to_summary("SingleWork Migration Strategy Processing Bag ITEM@#{@bag.item.item_id}")
        data = process_bag_metadata(@bag)
        file_ids = upload_files(@bag, @server)
        data[@work_type_node.uploaded_files_field_name] = @work_type_node.uploaded_files_field(file_ids)
        work_response = @server.submit_new_work(@bag, data)
        log_to_summary("Work #{work_response.dig('work', 'id')} created at #{work_response.dig('uri')}")
        @logger.warn('Not configured to advance work through workflow') unless @server.should_advance_work?
        workflow_response = advance_workflow(work_response, @server) if @server.should_advance_work?
      rescue StandardError => e
        log_to_summary("[ERROR] Failed processing: #{e.message} :\n\t #{e.backtrace.join("\n\t")}")
        raise e
      end

      private

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
    end
  end
end
