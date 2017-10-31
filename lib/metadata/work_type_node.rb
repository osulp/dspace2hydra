# frozen_string_literal: true
module Metadata
  class WorkTypeNode
    include Loggable
    attr_reader :config, :qualifier

    def initialize(work_type_config, config = {})
      @logger = Logging.logger[self]
      @config = config
      @work_type_config = work_type_config
      @work_type = work_type_config['work_type']
    end

    def in_works_field_name
      @in_works_field_name ||= format(@work_type_config.dig('in_works', 'field', 'property'),
                                      field_name: @work_type_config.dig('in_works', 'field', 'name'),
                                      work_type: @work_type_config.dig('work_type'))
    end

    def in_works_field(id)
      return [id] if @work_type_config.dig('in_works', 'field', 'type').casecmp('array').zero?
      return id if @work_type_config.dig('in_works', 'field', 'type').casecmp('string').zero?
    end

    def parent_field_name
      @parent_field_name ||= format(@work_type_config.dig('parent_work', 'field', 'property'),
                                    field_name: @work_type_config.dig('parent_work', 'field', 'name'))
    end

    def uploaded_files_field_name
      @uploaded_files_field_name ||= format(@work_type_config.dig('uploaded_files', 'field', 'property'),
                                            field_name: @work_type_config.dig('uploaded_files', 'field', 'name'))
    end

    def uploaded_files_field(ids)
      raise 'Cannot configure uploaded_files.field.type as anything other than an array.' unless @work_type_config.dig('uploaded_files', 'field', 'type').casecmp('array').zero?
      [ids].flatten
    end

    def selected_files_field_name
      @selected_files_field_name ||= format(@work_type_config.dig('selected_files', 'field', 'property'),
                                            field_name: @work_type_config.dig('selected_files', 'field', 'name'))
    end

    def selected_files_field(urls)
      raise 'Cannot configure selected_files.field.type as anything other than a hash.' unless @work_type_config.dig('selected_files', 'field', 'type').casecmp('hash').zero?
      # convert array of urls to hash (ie. { 0 => { :url => "file://path/to/file" }, 1 => { :url => "file://path/to/file2" } })
      urls.map.with_index { |u, i| [i, {url: u}] }.to_h
    end
  end
end
