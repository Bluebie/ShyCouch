require 'test/unit'
require_relative '../lib/ShyCouch.rb'

class CampingIntegrationTests
  
  class TestModelInheritence < Test::Unit::TestCase
    
    class InheritanceTest < ShyCouch::Data::CouchDocument; end
    def test_document_kind_assignment
         m = InheritanceTest.new
         assert_equal(InheritanceTest.to_s, m.kind)
    end
    
  end
end