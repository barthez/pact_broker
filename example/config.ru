require 'fileutils'
require 'logger'
require 'sequel'
# require 'pg' # for postgres
require 'pact_broker'

ENV['RACK_ENV'] ||= 'production'

# Create a real database, and set the credentials for it here
# It is highly recommended to set the encoding to utf8
DATABASE_CREDENTIALS = {adapter: "sqlite", database: "pact_broker_database.sqlite3", :encoding => 'utf8'}

# Hacky fix to let us get the text/plain version of the matrix
require 'rack/pact_broker/request_target'

module Rack
  module PactBroker
    module RequestTarget
      API_CONTENT_TYPES = %w[application/hal+json application/json text/csv application/yaml text/plain].freeze
    end
  end
end

# For postgres:
#
# $ psql postgres -c "CREATE DATABASE pact_broker;"
# $ psql postgres -c "CREATE ROLE pact_broker WITH LOGIN PASSWORD 'CHANGE_ME';"
# $ psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE pact_broker TO pact_broker;"
#
# DATABASE_CREDENTIALS = {adapter: "postgres", database: "pact_broker", username: 'pact_broker', password: 'CHANGE_ME', :encoding => 'utf8'}

# Have a look at the Sequel documentation to make decisions about things like connection pooling
# and connection validation.

ENV['TZ'] = 'Australia/Melbourne' # Set the timezone you want your dates to appear in

app = PactBroker::App.new do | config |
  # change these from their default values if desired
  # config.log_dir = "./log"
  # config.auto_migrate_db = true
  config.database_connection = Sequel.connect(DATABASE_CREDENTIALS.merge(:logger => PactBroker::DB::LogQuietener.new(config.logger)))
end

run app
