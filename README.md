[![CircleCI](https://circleci.com/gh/osulp/dspace2hydra/tree/master.svg?style=svg)](https://circleci.com/gh/osulp/dspace2hydra/tree/master)
[![Coverage Status](https://coveralls.io/repos/github/osulp/dspace2hydra/badge.svg?branch=master)](https://coveralls.io/github/osulp/dspace2hydra?branch=master)

# What is dspace2hydra?

Dspace2hydra (d2h) was built to facilitate bulk automated data and item migration from Dspace to a Hydra based server instance, such as Hyrax. D2h uses a combination of YAML configurations and Ruby mapping methods to translate, lookup, query, or otherwise process metadata values present in a Dspace metadata file. Every value in a Dspace item metadata file must be explicitly configured for migration to help prevent missing data during the process. Dspace data files are uploaded into Hydra and the metadata is transformed into the appropriate shape before being posted to the Hydra server to create a new instance of a configured type of work.

# Dependencies
- Ruby 2.3
- [Hyrax](https://github.com/projecthydra-labs/hyrax) based application instance (our goal is to be ready for the Hyrax 1.0 release)
- Dspace generated BAG files (we use [dspace-replicate](https://github.com/DSpace/dspace-replicate) to generate ours)

# Is it ready for me to use?

Not yet. We're getting closer by the day, and our migration timeline depends on this application as well as Hyrax 1.0. We are targeting May - June for our migration.

# How can I help?

Right now it would be most useful to get feedback or issues created to express the functionality your institution would like to see in this application. Depending on the scope of the request, we will do our best to design the application to facilitate the need and functionality you express.

