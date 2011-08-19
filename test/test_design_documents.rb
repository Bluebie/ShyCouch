require 'test/unit'
require_relative '../lib/ShyCouch.rb'

class DesignDocumentTests
  class TestDesignDocumentCreation < Test::Unit::TestCase
    Design = ShyCouch::Data::Design
    def setup; end
    def teardown; end
    
     class TestDesign < Design
        def view_cigars
          map do
            
          end
          reduce do
            
          end
        end
      end
    def test_define_design_document
      #todo
      
    end
  end
end