# frozen_string_literal: true
module Work
  module MigrationStrategy
    class ParentWithChildren < Base
      include Loggable

      ##
      # Creates a parent work that has no associated file(s), and a related child work for each file in the bag
      # that is identified as being a file to upload to the server. The process flow for this migration strategy
      # is as follows;
      #
      # 1. Process the metadata, publish the parent work, and track the ID it was minted from the server.
      # 2. Iterate through each upload file, resetting its metadata to include only the
      #    bare minimum necessary for ingesting. Set 'Title' to be the filename of the uploaded file.
      # 3. Associate the child work to the parent ID from step #1, and publish the work.
      def process_bag
        log_to_summary('----------------------------------------------------------------------------------')
        log_to_summary("ParentWithChildren Migration Strategy Processing Bag ITEM@#{@bag.item.item_id}")

        data = process_bag_metadata(@bag)
        parent_id = get_or_publish_parent(data)
        publish_children_works(parent_id, data)
      rescue StandardError => e
        log_to_summary("[ERROR] Failed processing: #{e.message} :\n\t #{e.backtrace.join("\n\t")}")
        raise e
      end

      private

      def get_or_publish_parent(data)
        id = @config.dig('parent_id')
        if id.nil?
          parent_work_response = publish_parent_work(data)
          id = parent_work_response.work.dig('id')
        end
        id
      end

      def skip_children_indexes
        children_indexes = @config.dig('skip_children') || []
        return children_indexes.split(',').map{ |index| index.to_i } unless children_indexes.empty?
        children_indexes
      end

      def publish_parent_work(data)
        work_response = @server.submit_new_work(@bag, data, 'parent')
        log_to_summary("[Parent] work #{work_response.dig('work', 'id')} created at #{work_response.dig('uri')}")
        @logger.warn('[Parent] Not configured to advance work through workflow') unless @server.should_advance_work?
        workflow_response = advance_workflow(work_response, @server) if @server.should_advance_work?
        work_response
      end

      def publish_children_works(parent_id, data)
        children_work_responses = []
        @bag.files_for_upload.each_with_index do |item_file, index|
          if skip_children_indexes.include?(index)
            @logger.info("[Child #{index}] Command line argument indicated to skip processing this child.")
          else
            begin
              file = process_file(item_file)
              data = set_work_metadata(data, file: file,
                                             parent_id: parent_id,
                                             item_file_name: item_file.name)
              work_response = @server.submit_new_child_work(@bag, data, parent_id, "child-#{index}")
              log_to_summary("[Child #{index}] work #{work_response.dig('work', 'id')} created at #{work_response.dig('uri')}")
              children_work_responses << work_response
              @logger.warn("[Child #{index}] Not configured to advance work through workflow") unless @server.should_advance_work?
              workflow_response = advance_workflow(work_response, @server) if @server.should_advance_work?
            rescue => e
              log_to_summary("[Child #{index}] Failed processing: #{e.message} :\n\t #{e.backtrace.join("\n\t")}")
            end
          end
        end
        children_work_responses
      end

      def set_work_metadata(data, values = {})
        file = values[:file]
        parent_id = values[:parent_id]
        item_file_name = values[:item_file_name]
        creator = data.dig(@work_type, 'creator')
        keyword = data.dig(@work_type, 'keyword')
        visibility = data.dig(@work_type, 'visibility')
        rights_statement = data.dig(@work_type, 'rights_statement')
        admin_set_id = data.dig(@work_type, 'admin_set_id')

        data[@work_type] = {}
        data[@work_type_node.uploaded_files_field_name] = @work_type_node.uploaded_files_field(file)
        data[@work_type_node.selected_files_field_name] = @work_type_node.selected_files_field(file) if file =~ "file://"
        data[@work_type_node.parent_field_name] = parent_id
        data = set_deep_field_property(data, @work_type_node.in_works_field(parent_id), *@work_type_node.in_works_field_name.split('.'))
        data[@work_type]['title'] = [item_file_name]
        data[@work_type]['creator'] = creator
        data[@work_type]['keyword'] = keyword
        data[@work_type]['rights_statement'] = rights_statement
        data[@work_type]['admin_set_id'] = admin_set_id
        data[@work_type]['visibility'] = visibility
        data
      end

      ##
      # Depending on if the commandline argument for file upload path was set (-u PATH), either
      # copy the file into place, or upload the file over the wire.
      # @param [ItemFile] item_file - the file to upload
      # @return String - the id that was assigned on the server, or the file url for the copied file
      def process_file(item_file)
        if item_file.upload_file_path
          @logger.info("[Child #{index}] Copying file in bag to path: #{item_file.upload_full_path}")
          item_file.copy_to_upload_full_path
          file = item_file.upload_file_url
        else
          item_file.copy_to_metadata_full_path
          @logger.info("[Child #{index}] Uploading filename from metadata to server: #{item_file.metadata_full_path}")
          file = upload_file(item_file)
          item_file.delete_metadata_full_path
        end
        file
      end

      ##
      # Upload a file to the server and fetch the id it was assign on the server side.
      # @param [ItemFile] item_file - the file to upload
      # @return [Array] - the id that was assigned on the server
      def upload_file(item_file)
        upload_response = @server.upload(item_file.file(item_file.metadata_full_path))
        json = JSON.parse(upload_response.body)
        json['files'].map { |f| f['id'] }
      end
    end
  end
end
