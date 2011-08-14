require '~/dev/shycouch/shycouch'
module ShyCouchTests
  def self.test_up
    begin
      # set everything up
      $t_database, $t_id, $t_document = ShyCouch::CouchDatabase.allocate, "", ShyCouch::Data::CouchDocument.new

      #set up the database
      setup_database
      setup_document
      test_model
      test_doc_kinds
      # check that everything at least exists
	    result = if $t_database and $t_database.server and $t_id and $t_document #and $test_doc_kinds.length == 1
	      {"ok"=>true,"message"=>"Test environment appears to work","database"=>"$t_database",
	        "server connection"=>"$t_database.server","test doc id"=>"$t_id", "test document"=>"$t_doc",
	        "test doc model"=>"$t_model"}
        else
          {"ok"=>false,"message"=>"Test environment appears not to be working","database"=>$t_database,
            "server connection"=>$t_database.server,"test doc id"=>$t_id,"test document"=>$t_doc}
        end
    rescue Errno::ECONNREFUSED
	    result = {"ok"=>false, "message"=>"""Server Connection refused.
	      Is CouchDB running at http://#{$t_database.host}:#{$t_database.port} ?"""}
    end
    result.each do |k, v| puts "#{k}: #{v}"; end
    result["ok"]
  end

  def self.test_down
    $t_database.server.delete_db('test')
    $t_database = nil
    $t_id = nil
    $t_doc = nil
    result = {"ok"=>true, "message"=>"Test environment has been brought down."}
    result.each do|k, v| puts "#{k}: #{v}"; end
  end

  class TestModel < ShyCouch::Data::CouchDocument
    def initialize hash
      requirements = {
        "me"=>String,
        "you"=>Array
      }
      super hash, requirements
    end
  end

  private

  def self.setup_database
    settings = {
      "db"=> {
          "host" => "localhost",
          "port" => 5984,
          "name" => "test",
          "user" => "cerales",
          "password" => "password"
        },
    }
    $t_database = ShyCouch::Create.go(settings)
    raise Errno::ECONNREFUSED unless $t_database.connect["ok"]
    $t_database.create_on_server unless $t_database.exists_on_server?
  end

  def self.setup_document
    if $t_database.all_docs.length == 0
      emptyDoc = ShyCouch::Data::CouchDocument.new
      #$t_id = $t_database.server.push_document($t_database, emptyDoc)["id"]
      $t_id = $t_database.push_document(emptyDoc)["id"]
    else
      $t_id = $t_database.all_docs[0]["id"]
    end
  end

  def self.test_doc_kinds
    doc = ShyCouch::Data::CouchDocument.new.merge!("kind"=>"test")
    doc2 = ShyCouch::Data::CouchDocument.new.merge!("kind"=>"nope")
    doc3 = ShyCouch::Data::CouchDocument.new.merge!("kind"=>"not me!")
    $t_database.push_document(doc)
    $t_database.push_document(doc2)
    $t_database.push_document(doc3)
    $t_doc_kind = $t_database.all_docs_with("kind", "not me!")
  end

  def self.test_model
    $t_document.merge!($t_database.get_document($t_id))
  end
end