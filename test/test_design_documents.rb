require 'test/unit'
require_relative '../lib/ShyCouch.rb'

class DesignDocumentTests
  class TestDesignDocument < Test::Unit::TestCase
    Design = ShyCouch::Data::Design
    CouchDocument = ShyCouch::Data::CouchDocument
    
    class Recipe < CouchDocument
      
    end
    
    def setup
      valid_settings = $settings
      @couchdb = ShyCouch.getDB(valid_settings)
      @views = setup_views
      @design = nil
    end
    def teardown
      @couchdb.delete_database
      @couchdb = nil
    end
    

    
    def test_create_design
      assert_nothing_raised {
        @design = setup_design_document
      }
    end
    
    def test_push_to_db
      design = setup_design_document
      @couchdb.add_design_documents_and_push(design)
      new_doc = @couchdb.get_design_document_by_id(design._id)
      assert_equal(design.as_hash, new_doc.as_hash)
    end
    
    def test_call_views
      design = setup_design_document
      @couchdb.add_design_documents_and_push(design)
      add_some_documents
      puts design.views["count_recipes"]
      require 'irb'
      IRB.start
    end
    
    def setup_views
      view1 = ShyCouch::Data::View.new :recipes do
        map do
          emit(doc._id, doc.name) if doc.kind == 'Recipe'
        end
      end
      view2 = ShyCouch::Data::View.new :count_recipes do
        map do
          emit(doc._id) if doc.kind == 'Recipe'
        end
        reduce do
          return sum(values)
        end
      end
      return [view1, view2]
    end
    def setup_design_document
      return ShyCouch::Data::Design.new :test_design, @views
    end
    def add_some_documents
      4.times do
        Recipe.new.push(@couchdb)
      end
    end
  end
end