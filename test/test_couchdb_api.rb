require 'test/unit'
require_relative '../lib/ShyCouch.rb'

class TestCouchDBAPI < Test::Unit::TestCase
  def setup
    valid_settings = $settings
    $database = ShyCouch.create(valid_settings)
  end
  
  def teardown
    $database.delete_database
    $database = nil
  end
  
  def test_connection
    assert_equal(true, $database.connect["ok"])
  end
end