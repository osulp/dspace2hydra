# frozen_string_literal: true
require 'mechanize'
require 'json'

class HydraEndpoint
  def initialize(config, started_at = DateTime.now)
    @agent = Mechanize.new
    @config = config
    login
    @csrf_token = get_csrf_token
    @started_at = started_at
  end

  ##
  # Upload a `File` to the application using the CSRF token in the form provided
  # @return [Mechanize::Page] the page result after uploading file, this is typically a json payload in the page.body
  def upload(file)
    post_data @config['uploads']['url'], "#{@config['new_work']['csrf_form_field']}": @csrf_token, "#{@config['uploads']['files_form_field']}": file
  end

  ##
  def submit_new_work(bag, data)
    cache_data data, bag.item_cache_path
    csrf_token = @csrf_token || get_csrf_token
    data[(@config['new_work']['csrf_form_field']).to_s] = csrf_token
    post_data @config['new_work']['form_action'], data
  end

  private

  def get_page(url)
    @agent.get(url)
  end

  def post_data(url, data = {}, headers = {})
    @agent.post(url, data, headers)
  rescue Mechanize::ResponseCodeError => e
    pp e
  end

  ##
  # Login to the Hydra application
  # @return [Mechanize::Page] the page result, after redirects, after logging in. (ie. Hydra dashboard)
  def login
    page = get_page(@config['login']['url'])
    # use the first form on the login page unless the forms id is set in the configuration
    form = @config['login']['form_id'] ? page.form_with(id: @config['login']['form_id']) : page.forms.first
    form.field_with(name: @config['login']['username_form_field']).value = @config['login']['username']
    form.field_with(name: @config['login']['password_form_field']).value = @config['login']['password']
    @agent.submit form
  end

  def get_csrf_token
    new_work_page = get_page(@config['new_work']['url'])
    new_work_form = new_work_page.form_with(action: @config['new_work']['form_action'])
    new_work_form.field_with(name: @config['new_work']['csrf_form_field']).value
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
end
