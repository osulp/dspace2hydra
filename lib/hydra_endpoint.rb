# frozen_string_literal: true
require 'mechanize'
require 'json'

class HydraEndpoint
  Response = Struct.new(:work, :uri)

  def initialize(config, work_type_config, started_at = DateTime.now)
    @agent = Mechanize.new
    @config = config
    @work_type_config = work_type_config
    @csrf_token = get_csrf_token(login_url)
    login
    @started_at = started_at
  end

  ##
  # Configuration to determine if the work sould be automatically advanced, will default to true.
  # @return [Boolean] - true if the configuration is unset, otherwise returns the value of the configuration
  def should_advance_work?
    config = @work_type_config.dig('hydra_endpoint', 'workflow_actions', 'auto_advance_work')
    config = @config.dig('workflow_actions', 'auto_advance_work') if config.nil?
    config.nil? ? true : config
  end

  def server_domain
    url = @work_type_config.dig('hydra_endpoint', 'server_domain')
    url = @config.dig('server_domain') unless url
    URI.parse(url.gsub(/\/$/, ''))
  end

  def new_work_url
    url = @work_type_config.dig('hydra_endpoint', 'new_work', 'url')
    url = @config.dig('new_work', 'url') unless url
    URI.join(server_domain, url)
  end

  def new_work_action
    form_action = @work_type_config.dig('hydra_endpoint', 'new_work', 'form_action')
    form_action = @config.dig('new_work', 'form_action') unless form_action
    form_action
  end

  def uploads_url
    url = @config.dig('uploads', 'url')
    URI.join(server_domain, url)
  end

  def login_url
    url = @config.dig('login', 'url')
    URI.join(server_domain, url)
  end

  def csrf_form_field
    @config.dig('csrf_form_field')
  end

  def workflow_actions_url(id)
    url = @work_type_config.dig('hydra_endpoint', 'workflow_actions', 'url')
    url = @config.dig('workflow_actions', 'url') unless url
    URI.join(server_domain, format(url, id: id))
  end

  ##
  # Generate the workflow_action field with value from configuration
  # @param [String] property_name - the field.name from configuration with preference to setting found in the work_type specific file
  # @return [Hash] - the workflow_action property and value, like {workflow_action: { comment: "Some comment"}}
  def workflow_actions_data(property_name)
    name = @work_type_config.dig('hydra_endpoint', 'workflow_actions', property_name, 'field', 'name')
    name = @config.dig('workflow_actions', property_name, 'field', 'name') unless name
    property = @work_type_config.dig('hydra_endpoint', 'workflow_actions', property_name, 'field', 'property')
    property = @config.dig('workflow_actions', property_name, 'field', 'property') unless property
    type = @work_type_config.dig('hydra_endpoint', 'workflow_actions', property_name, 'field', 'type')
    type = @config.dig('workflow_actions', property_name, 'field', 'type') unless type
    value = @work_type_config.dig('hydra_endpoint', 'workflow_actions', property_name, 'value')
    value = @config.dig('workflow_actions', property_name, 'value') unless value
    value = [value] if type.casecmp('array').zero?

    # "workflow_action.comment" becomes { workflow_action: { comment: "Some value from configuration" }}
    workflow_action, prop = format(property, field_name: name).split('.')
    { "#{workflow_action}" => { "#{prop}" => value } }
  end

  ##
  # Upload a `File` to the application using the CSRF token in the form provided
  # @param [File] file - the file stream to upload to the server
  # @return [Mechanize::Page] the page result after uploading file, this is typically a json payload in the page.body
  def upload(file)
    data = csrf_token_data
    data.merge!("#{@config.dig('uploads','files_form_field')}": file) { |k, a, b| a.merge b }
    post_data uploads_url, data
  end

  ##
  # Cache the data and submit a new work related to the bag, and processed metadata
  # @param [Metadata::Bag] bag - the bag containing the item to be migrated
  # @param [Hash] data - the metadata after mapping/lookup/processing
  # @param [Hash] headers - any HTTP headers necessary for POST to the server
  # @return [HydraEndpoint::Response] - the work and location struct containing the result of publishing
  def submit_new_work(bag, data, headers = {})
    cache_data data, bag.item_cache_path
    publish_work(data, headers)
  end

  ##
  # Publish the work to the server
  # @param [Hash] data - the metadata after mapping/lookup/processing
  # @param [Hash] headers - any HTTP headers necessary for POST to the server
  # @return [HydraEndpoint::Response] - the work and location struct containing the result of publishing
  def publish_work(data, headers = {})
    # TODO: Add logging for this method
    data.merge! csrf_token_data
    headers = json_headers(headers)
    response = post_data(new_work_action, JSON.generate(data), headers)
    Response.new JSON.parse(response.body), URI.join(server_domain, response['location'])
  end

  ##
  # Advance this work to the configured workflow step and with the configured workflow comment.
  # This is generally used to advance the work directly to the deposited (approved) state.
  # @param [HydraEndpoint::Response] response - the work and location struct to advance
  # @param [Hash] headers - any HTTP headers necessary for POST to the server
  # @return [HydraEndpoint::Response] - the work and location struct containing the result of publishing
  def advance_workflow(response, headers = {})
    # TODO: Add logging for this method
    data = csrf_token_data
    data.merge!(workflow_actions_data('name')) { |_k, a, b| a.merge b }
    data.merge!(workflow_actions_data('comment')) { |_k, a, b| a.merge b }
    headers = json_headers(headers)
    url = workflow_actions_url(response.dig('work', 'id'))
    response = put_data(url, JSON.generate(data), headers)
    Response.new JSON.parse(response.body), URI.join(server_domain, response['location'])
  end

  def clear_csrf_token
    @csrf_token = nil
  end

  # :nocov:
  private

  def post_data(url, data = {}, headers = {})
    @agent.post(url, data, headers)
  rescue Mechanize::ResponseCodeError => e
    pp e
  end

  def put_data(url, data = {}, headers = {})
    @agent.put(url, data, headers)
  rescue Mechanize::ResponseCodeError => e
    pp e
  end

  ##
  # Login to the Hydra application
  # @return [Mechanize::Page] the page result, after redirects, after logging in. (ie. Hydra dashboard)
  def login
    page = @agent.get(login_url)
    form = page.form_with(id: @config.dig('login', 'form_id'))
    form.field_with(name: @config.dig('login', 'username_form_field')).value = @config.dig('login', 'username')
    form.field_with(name: @config.dig('login', 'password_form_field')).value = @config.dig('login', 'password')
    @agent.submit form
    clear_csrf_token
  end

  ##
  # Make a backup of the data being posted to the server prior to sending it.
  # @param [Hash] data - the data being posted to the server
  # @param [String] item_cache_directory - the full path to the directory for cached data
  def cache_data(data, item_cache_directory)
    timestamp = @started_at.strftime('%Y%m%d%H%M%S')
    File.open(File.join(item_cache_directory, "#{timestamp}_data.json"), 'w+') do |file|
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
    @csrf_token = get_csrf_token(new_work_url) if @csrf_token.nil?
    { "#{csrf_form_field}" => @csrf_token }
  end

  def get_csrf_token(url)
    page = @agent.get(url)
    page.at("[name='#{csrf_form_field}']").attr('value')
  end
end
