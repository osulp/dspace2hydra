[![CircleCI](https://circleci.com/gh/osulp/dspace2hydra/tree/master.svg?style=svg)](https://circleci.com/gh/osulp/dspace2hydra/tree/master)
[![Coverage Status](https://coveralls.io/repos/github/osulp/dspace2hydra/badge.svg?branch=master)](https://coveralls.io/github/osulp/dspace2hydra?branch=master)

# What is dspace2hydra?

Dspace2hydra (d2h) was built to facilitate bulk automated data and item migration from Dspace to a Hydra based server instance, such as Hyrax. D2h uses a combination of YAML configurations and Ruby mapping methods to translate, lookup, query, or otherwise process metadata values present in a Dspace metadata file. Every value in a Dspace item metadata file must be explicitly configured for migration to help prevent missing data during the process. Dspace data files are uploaded into Hydra and the metadata is transformed into the appropriate shape before being posted to the Hydra server to create a new instance of a configured type of work.

# Dependencies

- Ruby 2.3
- [Hyrax](https://github.com/samvera/hyrax) based application instance
- Dspace generated BAG files (we use [dspace-replicate](https://github.com/DSpace/dspace-replicate) to generate ours)
- Export DSpace BAGs via command line: [DSpace]/bin/dspace curate -t transmitaip -i handle -v

# Quick Start D2H migration with a basic Hyrax App

## Build a [basic Hyrax Application](https://github.com/samvera/hyrax#creating-a-hyrax-based-app)

- Generate a Hyrax work type called 'Default'
- `$rails g hyrax:work Default`

## Register a user to operate as the migration user

- Start the server `bin/rails hydra:server`
- Register a new user the application (ex. admin_user@hydra.server)
- Make the new user an admin by adding configuration on the `config/role_map.yml`

```
  development:
    ...
    admin:
      - admin_user@hydra.server
```

## Add authentication bypass for the D2H user (intended only to be used during active migration)

- Update to `app/controllers/application_controller.rb`, include a method to evaluate if the username and token are being used by D2H.

```
  ...
  protect_from_forgery with: :exception, unless: :d2h_authenticated

  private
  # Could be any logic you choose, this just expects an ENV variable with the username and token to match the configuration
  # found in D2H .config.yml.
  def d2h_authenticated
    if request.headers.key?('HTTP_D2H_AUTHENTICATION')
      env_token = ENV['HTTP_D2H_AUTHENTICATION_TOKEN']
      env_username = ENV['HTTP_D2H_AUTHENTICATION_USERNAME']
      raise 'Invalid or missing ENV variables HTTP_D2H_AUTHENTICATION_TOKEN and HTTP_D2H_AUTHENTICATION_USERNAME' unless env_token && env_username
      username, token = request.headers['HTTP_D2H_AUTHENTICATION'].split('|')
      return false if token == env_token && username == env_username
    end
    true
  end
```

## Start the Hyrax application

- Stop the server if it is already running.
- Export the D2H related ENV variables for use with authentication, see D2H .config.example.yml, these should all match the user credentials you created for your new user
- Restart the server

```
$export D2H_HTTP_AUTHENTICATION_TOKEN=abc123
$export D2H_HTTP_AUTHENTICATION_USERNAME=admin_user@hydra.server
$bin/rails hydra:server
```

## Setup D2H .config.yml

- Change to the D2H path
- `$cp .config.example.yml .config.yml`
- Update `.config.yml`
  - Update username, password, authentication_token
  - Update server_domain

## Migrate the example work

- Change to the D2H path
- `$ruby dspace2hydra.rb -c example/_default_work.example.yml -b example/ITEM@1957-33356`

# How can I help?

Right now it would be most useful to get feedback or issues created to express the functionality your institution would like to see in this application. Depending on the scope of the request, we will do our best to design the application to facilitate the need and functionality you express.
