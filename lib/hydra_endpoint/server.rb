# frozen_string_literal: true
module HydraEndpoint
  class Server
    include Loggable
    include Configuration
    Response = Struct.new(:work, :uri)

    CACHE_ROOT = 'cache'

    def initialize(config, work_type_config, started_at = DateTime.now)
      @logger = Logging.logger[self]
      @logger.debug('initializing hydra endpoint connection')
      @config = config
      @work_type_config = work_type_config
      @agent = Mechanize.new
      @agent.read_timeout = server_timeout
      login
      cache_admin_sets
      @started_at = started_at
    end

    ##
    # Upload a `File` to the application using the CSRF token in the form provided
    # @param [File] file - the file stream to upload to the server
    # @return [Mechanize::Page] the page result after uploading file, this is typically a json payload in the page.body
    def upload(file)
      data = csrf_token_data
      data.merge!("#{@config.dig('uploads', 'files_form_field')}": file) { |_k, a, b| a.merge b }
      @logger.debug("uploading file : #{file.path}")
      post_data uploads_url, data
    end

    ##
    # Cache the data and submit a new work related to the bag, and processed metadata
    # @param [Metadata::Bag] bag - the bag containing the item to be migrated
    # @param [Hash] data - the metadata after mapping/lookup/processing
    # @param [String] file_name_segment - an optional argument for specifying the cached data file_name format
    # @param [Hash] headers - any HTTP headers necessary for POST to the server
    # @return [HydraEndpoint::Response] - the work and location struct containing the result of publishing
    def submit_new_work(bag, data, file_name_segment = 'data', headers = {})
      cache_data data, bag.item_cache_path, file_name_segment
      publish_work(data, new_work_action, headers)
    end

    def submit_new_child_work(bag, data, parent_id, file_name_segment = 'data', headers = {})
      cache_data data, bag.item_cache_path, file_name_segment
      publish_work(data, new_child_work_action(parent_id), headers)
    end

    ##
    # Publish the work to the server
    # @param [Hash] data - the metadata after mapping/lookup/processing
    # @param [String] action_url - the url to post data to the server
    # @param [Hash] headers - any HTTP headers necessary for POST to the server
    # @return [HydraEndpoint::Response] - the work and location struct containing the result of publishing
    def publish_work(data, action_url, headers = {})
      data.merge! csrf_token_data
      headers = json_headers(headers)
      @logger.debug("publishing work to #{action_url}")
      server_response = post_data(action_url, JSON.generate(data), headers)
      response = Response.new JSON.parse(server_response.body), URI.join(server_domain, server_response['location'])
      @logger.info("Work #{response.dig('work', 'id')} published at #{response.dig('uri')}")
      response
    end

    ##
    # Advance this work to the configured workflow step and with the configured workflow comment.
    # This is generally used to advance the work directly to the deposited (approved) state.
    # @param [HydraEndpoint::Response] response - the work and location struct to advance
    # @param [Hash] headers - any HTTP headers necessary for POST to the server
    # @return [HydraEndpoint::Response] - the work and location struct containing the result of publishing
    def advance_workflow(response, headers = {})
      data = csrf_token_data
      workflow_name = workflow_actions_data('name')
      workflow_comment = workflow_actions_data('comment')
      data.merge!(workflow_name) { |_k, a, b| a.merge b }
      data.merge!(workflow_comment) { |_k, a, b| a.merge b }
      headers = json_headers(headers)
      url = workflow_actions_url(response.dig('work', 'id'))
      @logger.info("Advancing workflow to: #{workflow_name}")
      response = put_data(url, JSON.generate(data), headers)
      Response.new JSON.parse(response.body), URI.join(server_domain, response['location'])
    end

    def clear_csrf_token
      @logger.debug('clearing csrf_token')
      @csrf_token = nil
    end

    # :nocov:
    private

    def cache_admin_sets
      response = @agent.get(admin_sets_url, [], nil, json_headers)
      items = JSON.parse(response.body)
      cache_file = File.join(CACHE_ROOT, 'admin_sets.yml')
      @logger.debug("caching admin_sets from server: #{cache_file}")
      File.open(cache_file, 'w+') do |file|
        file.write(items.to_yaml)
      end
    end

    def post_data(url, data = {}, headers = {})
      @logger.debug("POST data to: #{url}")
      @agent.post(url, data, headers)
    rescue Mechanize::ResponseCodeError => e
      @logger.fatal("POST data to #{url} handled HTTP Error : #{e}")
      raise e
    rescue StandardError => e
      @logger.fatal("POST data to #{url} caught an unhandled exception : #{e}")
      raise e
    end

    def put_data(url, data = {}, headers = {})
      @logger.debug("PUT data to: #{url}")
      @agent.put(url, data, headers)
    rescue Mechanize::ResponseCodeError => e
      @logger.fatal("PUT data to #{url} handled HTTP Error : #{e}")
      raise e
    rescue StandardError => e
      @logger.fatal("PUT data to #{url} caught an unhandled exception : #{e}")
      raise e
    end

    ##
    # Login to the Hydra application
    # @return [Mechanize::Page] the page result, after redirects, after logging in. (ie. Hydra dashboard)
    def login
      @logger.debug("logging into server at : #{login_url}")
      page = @agent.get(login_url, [], nil, authentication_header)
      form = page.form_with(id: @config.dig('login', 'form_id'))

      if form
        @csrf_token = page.at("[name='#{csrf_form_field}']").attr('value')
        form.field_with(name: @config.dig('login', 'username_form_field')).value = @config.dig('login', 'username')
        form.field_with(name: @config.dig('login', 'password_form_field')).value = @config.dig('login', 'password')
        @agent.submit form
      end
      clear_csrf_token
    rescue Mechanize::ResponseCodeError => e
      @logger.fatal("Login to #{login_url} handled HTTP Error : #{e}")
      raise e
    rescue StandardError => e
      @logger.fatal("Login to #{login_url} caught an unhandled exception : #{e}")
      raise e
    end

    ##
    # Make a backup of the data being posted to the server prior to sending it.
    # @param [Hash] data - the data being posted to the server
    # @param [String] item_cache_directory - the full path to the directory for cached data
    # @param [String] file_name_segment - a specific file name fragment for the cached data
    def cache_data(data, item_cache_directory, file_name_segment)
      timestamp = @started_at.strftime('%Y%m%d%H%M%S')
      cache_file = File.join(item_cache_directory, "#{timestamp}_#{file_name_segment}.json")
      @logger.debug("caching json before publishing work: #{cache_file}")
      File.open(cache_file, 'w+') do |file|
        file.write(JSON.pretty_generate(data))
      end
    end

    ##
    # Merge the json specific keys into the headers hash supplied.
    # @param [Hash] headers - any HTTP headers that need to be included in the server typically
    # @return [Hash] - a new Hash with the json HTTP headers included
    def json_headers(headers = {})
      json_headers = { 'Content-Type' => 'application/json',
                       'Accept' => 'application/json' }
      headers.merge(json_headers) { |_k, a, b| a.merge b }
    end

    ##
    # Get the CSRF token and its proper field name
    def csrf_token_data
      @logger.debug('csrf_token is empty') if @csrf_token.nil?
      @csrf_token = get_csrf_token(new_work_url) if @csrf_token.nil?
      { csrf_form_field.to_s => @csrf_token }
    end

    def get_csrf_token(url)
      @logger.debug("fetching csrf_token from input[name='#{csrf_form_field}'] on the page at : #{url}")
      page = @agent.get(url)
      page.at("[name='#{csrf_form_field}']").attr('value')
    rescue Mechanize::ResponseCodeError => e
      @logger.fatal("Get CSRF Token to #{url} handled HTTP Error : #{e}")
      raise e
    rescue StandardError => e
      @logger.fatal("Get CSRF token to #{url} caught an unhandled exception : #{e}")
      raise e
    end
  end
end
