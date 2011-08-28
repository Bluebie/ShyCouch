require 'test/unit'
require_relative '../lib/ShyCouch.rb'

class CouchDocumentTests# < Test::Unit::TestCase
  
  class TestDocumentCreation < Test::Unit::TestCase
    def setup
      valid_settings = $settings
      @couchdb = ShyCouch.create(valid_settings)
    end
    def teardown
      @couchdb.delete_database
      @couchdb = nil
    end

    def test_create_from_empty_hash
        # should be able to create a couch doc with a hash argument
        hash = {}
        couch_document = ShyCouch::Data::CouchDocument.new(hash)
        assert_kind_of(ShyCouch::Data::CouchDocument, couch_document)
    end
  
    def test_create_from_hash
      # should be able to create a couch doc with a hash argument
      hash = {"id" => "rejrandomrandomfhdjf", "rev"=>"1000000", "message"=>"up in here yo"}
      couch_document = ShyCouch::Data::CouchDocument.new(hash)
      assert_kind_of(ShyCouch::Data::CouchDocument, couch_document)
    end
  
    def test_create_from_string
      # Ensure no doc creation with fixnum argument
      string = "hehe i'm all over here you know"
      assert_raises IndexError do
        doc = ShyCouch::Data::CouchDocument.new(string)
      end
    end
  
    def test_create_from_fixnum
      # Ensure no doc creation with fixnum argument
      fixnum = 1
      assert_raise TypeError do
        doc = ShyCouch::Data::CouchDocument.new(fixnum)
      end
    end
    
  end
  
  class TestDocumentPulling < Test::Unit::TestCase
    #TODO
  end
  
  class TestDocumentPushing < Test::Unit::TestCase
    # assumes success of the stuff in TestDocumentPulling
    def setup
      valid_settings = $settings
      $couchdb = ShyCouch.create(valid_settings)
      
      
      @valid_documents = [
        ShyCouch::Data::CouchDocument.new({"kind"=>"post", "message"=>"BUY TRAMADOL ONLINE!!"}),
        ShyCouch::Data::CouchDocument.new({"kind"=>"comment",
            "message"=>"gry gry online gry gry online gry gry online gry gry online gry gry online "}),
        ShyCouch::Data::CouchDocument.new({"kind"=>"tag", "name"=>"FREE CANADIAN PRESCRIPTION DRUGS"}),
        ShyCouch::Data::CouchDocument.new({"kind"=>"helpers", 
            "helpers"=>["helper", "bad helper", "terrible helper", "this isn't helping"],
            "actually_helpful"=>false, "times_helped"=>0}),
        ]
      @existing_valid_documents = [
        ShyCouch::Data::CouchDocument.new("whatever"=>"yep"),
        ShyCouch::Data::CouchDocument.new("is_a_document"=>true, "number_of_docs_this_is"=>1)
      ].each { |doc|
        doc.push
      }
      @invalid_documents = nil # make sure user can't set rev maybe? or is that legal?
    end
    def teardown
      $couchdb.delete_database
      $couchdb = nil
      # delete the database
    end
    
    def test_keys_as_attr_accessors
      # tests that if there is a "phone" key on "doc" object you can do doc.phone
      @valid_documents.each { |doc| 
        doc.keys.each { |key|
          assert_respond_to(doc, key)
        }
      }
    end
    
    def test_push_new_documents
      @valid_documents.each { |doc|
        # put the document on the server, grab the server's response
        res = doc.push
        # check that the server included "ok"=>true in its response
        assert(res["ok"])
        # check that the doc now has an id and a rev
        assert(doc["_id"])
        assert(doc["_rev"])
        # get the new doc
        newDoc = $couchdb.get_document(doc._id)
        # test equality of all the attributes aside from id and rev on the new document
        doc.attr_keys.each { |k|
          assert_equal(doc["k"], newDoc["k"])
        }
      }
    end
    
    def test_change_existing_documents
      @existing_valid_documents.each { |doc| 
        # add some more attributes
        assert(doc._rev)
        doc["owner"] = "the guvvmint"
        doc["buttonCount"] = nil
        doc["friends"] = nil
        doc.buttonCount = 5
        doc.friends = ["alan", "alex", "all me other mates"]
        
        res = doc.push
        assert(res["ok"])
        
        # pull it from the database again
        checkDoc = $couchdb.get_document(doc._id)
        
        # check that the one from the database has all the new attributes
        assert_equal(doc.owner, checkDoc.owner)
        assert_equal(doc.buttonCount, checkDoc.buttonCount)
        assert_equal(doc.friends, checkDoc.friends)
      }
    end
  
    def test_illegal_change_to_rev
      @existing_valid_documents.each { |doc|
        doc._rev = "hurr"
        assert_raise RuntimeError do
          res = doc.push
        end
      }
    end
    
  end
end