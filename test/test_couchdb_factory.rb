require 'test/unit'
require_relative '../lib/ShyCouch.rb'

class TestCouchDBFactory < Test::Unit::TestCase
  def setup
    @valid_settings = $settings
  end
  
  def teardown
  end
  
  def test_create_database
    assert_kind_of(ShyCouch::CouchDatabase, ShyCouch.create(@valid_settings))
  end
end