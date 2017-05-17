# frozen_string_literal: true

module HydraEndpoint
  module Configuration
    include NestedConfiguration

    ##
    # Configuration to determine if the work sould be automatically advanced, will default to true.
    # @return [Boolean] - true if the configuration is unset, otherwise returns the value of the configuration
    def should_advance_work?
      get_configuration 'auto_advance_work', @work_type_config.dig('hydra_endpoint', 'workflow_actions'), @config.dig('workflow_actions')
    rescue
      true
    end

    ##
    # The timeout (in seconds) to wait for a response from the server, will default to 60
    # @return [Integer] - the server timeout, otherwise 60
    def server_timeout
      get_configuration 'server_timeout', @config
    rescue
      60
    end

    ##
    # The domain name of the server to connect to
    # @return [URI] - the server domain as a URI
    def server_domain
      url = get_configuration 'server_domain', @work_type_config.dig('hydra_endpoint'), @config
      URI.parse(url.gsub(/\/$/, ''))
    end

    ##
    # The url to the server for creating a new work
    # @return [URI] - the URI to posting a new work
    def new_work_url
      url = get_configuration 'url', @work_type_config.dig('hydra_endpoint', 'new_work'), @config.dig('new_work')
      URI.join(server_domain, url)
    end

    def new_work_action
      get_configuration 'form_action', @work_type_config.dig('hydra_endpoint', 'new_work'), @config.dig('new_work')
    end

    def new_child_work_action(parent_id)
      config = get_configuration 'form_action', @work_type_config.dig('hydra_endpoint', 'new_child_work'), @config.dig('new_child_work')
      format(config, parent_id: parent_id)
    end

    def uploads_url
      url = get_configuration 'url', @config.dig('uploads')
      URI.join(server_domain, url)
    end

    def login_url
      url = get_configuration 'url', @config.dig('login')
      URI.join(server_domain, url)
    end

    def authentication_header
      username = get_configuration 'username', @config.dig('login')
      authentication_token = get_configuration 'authentication_token', @config.dig('login')
      { 'D2H-AUTHENTICATION' => "#{username}|#{authentication_token}" }
    end

    def csrf_form_field
      get_configuration 'csrf_form_field', @config
    end

    def login_form_id
      get_configuration 'form_id', @config.dig('login')
    end

    def workflow_actions_url(id)
      url = get_configuration 'url', @config.dig('workflow_actions')
      URI.join(server_domain, format(url, id: id))
    end

    def admin_sets_url
      url = get_configuration 'url', @config.dig('admin_sets')
      URI.join(server_domain, url)
    end

    ##
    # Generate the workflow_action field with value from configuration
    # @param [String] property_name - the field.name from configuration with preference to setting found in the work_type specific file
    # @return [Hash] - the workflow_action property and value, like {workflow_action: { comment: "Some comment"}}
    def workflow_actions_data(property_name)
      # property config example:
      #
      # hydra_endpoint:
      #   workflow_actions:
      #     name:
      #       field:
      #         name: name                                  #for use with property string format
      #         property: 'workflow_action.%{field_name}'   #to create properly formed data
      #         type: String
      #       value: approve                                #the value expected for this data
      property_config = @config.dig('workflow_actions', property_name)
      name = get_configuration 'name', property_config.dig('field')
      property = get_configuration 'property', property_config.dig('field')
      type = get_configuration 'type', property_config.dig('field')
      value = get_configuration 'value', property_config
      value = [value] if type.casecmp('array').zero?

      # "workflow_action.comment" becomes { workflow_action: { comment: "Some value from configuration" }}
      workflow_action, prop = format(property, field_name: name).split('.')
      { workflow_action.to_s => { prop.to_s => value } }
    end
  end
end
