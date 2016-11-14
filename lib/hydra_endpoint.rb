require 'mechanize'

class HydraEndpoint

  def initialize(config)
    @agent = Mechanize.new
    @config = config
  end

  ##
  # Login to the Hydra application
  # @return [Mechanize::Page] the page result, after redirects, after logging in. (ie. Hydra dashboard)
  def login
    page = get_page(@config['login']['url'])
    #use the first form on the login page unless the forms id is set in the configuration
    form = @config['login']['form_id'] ? page.form_with(id: @config['login']['form_id']) : page.forms.first
    form.field_with(name: @config['login']['username_form_field']).value = @config['login']['username']
    form.field_with(name: @config['login']['password_form_field']).value = @config['login']['password']
    submit_form form
  end

  ##
  # Upload a `File` to the application using the CSRF token in the form provided
  # @return [Mechanize::Page] the page result after uploading file, this is typically a json payload in the page.body
  def upload(form, file)
    csrf = form.field_with(name: @config['new_work']['csrf_form_field'])
    post_data @config['uploads']['url'], { "#{csrf.name}": csrf.value, "#{@config['uploads']['files_form_field']}": file }
  end

  ##
  # Get the new work page
  # @return [Mechanize::Page] the page result at the new work url
  def new_work
    get_page(@config['new_work']['url'])
  end

  ##
  # Get the new work form on the page provided
  # @return [Mechanize::Form] the new work form
  def new_work_form(page)
    page.form_with(action: @config['new_work']['form_action'])
  end

  ##
  # @todo need to update the form and submit it?
  def submit_new_work(page, data)
    form = new_work_form page
    csrf = form.field_with(name: @config['new_work']['csrf_form_field'])

    #TODO: dynamically generate the field for keyword and determine visibility
    data.merge!({"#{csrf.name}": csrf.value, "generic_work[keyword][]": "data migration", "generic_work[visibility]": "open", "agreement": 1})
    post_data @config['new_work']['form_action'], data
  end

  private

  def get_page(url)
    @agent.get(url)
  end

  def post_data(url, data = {}, headers = {})
    begin
      @agent.post(url, data, headers)
    rescue Mechanize::ResponseCodeError => e
      pp e
    end
  end

  def submit_form(form)
    @agent.submit form
  end
end