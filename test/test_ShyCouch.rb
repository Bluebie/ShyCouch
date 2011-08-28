require 'test/unit'
require_relative '../lib/ShyCouch'

# Most of these tests require a working CouchDB installation to be up and running.
# All the tests that expect to work with the database will use the settings defined below.

# Settings for a database that is set up and working, with an admin user
$settings = {
  "db"=> {
      "host" => "ramponeau.local",
      # "host" => "localhost",
      "port" => 5984,
      "name" => "test",
      "user" => "cerales",
      "password" => "password"
    },
}

# test ShyCouch::CouchDBAPI
require_relative 'test_couchdb_api'

# test ShyCouch::Fields
# some of the tests in here are disabled cos they involve attempting to resolve a bad domain name
require_relative 'test_fields'

# test ShyCouch::Data::CouchDocument
require_relative 'test_couch_document'

require_relative 'test_camping_integration'

require_relative 'test_couchdb_factory'

require_relative 'test_design_documents'

require_relative 'test_views'