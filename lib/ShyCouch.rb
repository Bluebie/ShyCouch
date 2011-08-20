# July 2011
# This is a small Ruby layer for working with CouchDB
# Built primarily to allow Camping apps to use CouchDB for data persistence 
# ShyRubyJS is library used to build map and reduce functions from Ruby blocks

# Add the directory containing this file to the start of the load path if it
# isn't there already.
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'net/http'
require 'json'
require 'resolv'
require 'shyrubyjs'
# require everything from the 'ShyCouch' subdirectory
Dir.new(File.dirname(__FILE__)+'/ShyCouch').each { |f| require 'shycouch/' + f.split('.')[0] unless f == '.' or f == '..' }


module ShyCouch
  class << self
    def goes(m)
      Camping.goes m
      c = %{
        #{m.to_s}::Models::CouchDocument = ShyCouch::Data::CouchDocument
      }
      eval(c)
      ShyCouch.create
    end
    
    def create(settings=nil)
      $couchdb = ShyCouch.getDB(settings)
    end
    
    def getDB(settings=nil)
      settings = $settings unless settings
      database = CouchDBAPI.new(settings["db"]["host"], settings["db"]["port"], settings["db"]["name"], settings["db"]["user"], settings["db"]["password"])
      puts database.connect unless database.connect["ok"]
      database.create unless database.on_server?
      return database
    end
    
  end
  attr_accessor :database
  
  class Connection
    # Test that the database is accessible and give back a CouchDBAPI object if so.
    # Doesn't actually gets instantiated - is just here to allow nice ShyCouch::Connection.Create syntax
    # def self.Create(settings=nil)
    #   settings = $settings unless settings
    #   database = CouchDBAPI.new(settings["db"]["host"], settings["db"]["port"], settings["db"]["name"], settings["db"]["user"], settings["db"]["password"])
    #   puts database.connect unless database.connect["ok"]
    #   database.create unless database.on_server?
    #   return database
    # end
    
    def push_generic_views
      #TODO 
    end
  end

  class CouchDBAPI
  	def initialize(host, port, name, user, password)
  		@host, @port, @name, @user, @password = host, port, name, user, password
  		@views = []
  		@server = CouchServerConnection.allocate
  	end
    # 
    # def initialize(*settings)
    #   @host, @port, @name, @user, @password = settings["db"]["host"], settings["db"]["port"], settings["db"]["name"], settings["db"]["user"], settings["db"]["password"]
    #     end

  	attr_accessor :server, :name, :host, :port, :views

  	def connect
  		@server = CouchServerConnection.new({"host"=>@host, "port"=>@port, "user"=>@user, "password"=>@password})
  		if @server.responds?
  			return {"ok"=>true, "message"=>"Successfully connected to the couch database at #{@host}: #{@port}."}
  		else
  			return {"ok"=>false, "message"=>"Could not connect to the couch database."}
  		end
  	end
  	def delete_database
  	  @server.delete_db(self.name)
	  end
  	def server_responds?; return @server.responds?; end

  	def on_server?
  		@server.has_database?(@name)
  	end

  	def create
  		@server.create_db(@name)
  	end
    def get_document(id)
      @server.get_document(@name, id)
    end
    def all_docs
      get_document('_all_docs').rows.map { |doc|
        get_document(doc["id"])
      }
    end
    def all_docs_with(attribute, value=nil)
      #TODO - change this to build a couch map query, cache it in couch then call it
      # maybe?!?!
      docs = []
      all_docs.each do |doc|
        if value
          docs << doc if doc[attribute] == value
        else
          docs << doc if doc[attribute]
        end
      end
      return docs
    rescue NameError
    end
    def uri
      return "http://#{host}/#{port}/#{name}"
    end

    def pull_document(document)
      @server.push_document(self.name, document)      
    end

    def push_document(document)
      @server.push_document(self.name, document)
    end
    
    def designs
      @server.pull_all_design_docs(self.name)
    end
    
    def views
      designs.map{ |d| d["views"] }
    end
    
    private 
    class CouchServerConnection
    	def initialize(args, options=nil)#host, port, user, password, options = nil)
    		@host = args["host"]
    		@port = args["port"]
    		@user = args["user"]
    		@password = args["password"]
    		@options = options
    	end

    	def responds?
    		if get('/')['couchdb'] == "Welcome"
    			true
    		else
    			false
    		end
    	rescue Errno::ECONNREFUSED
    		false
    	end

    	def has_database?(db_name)
    		get("/#{db_name}/")
    		true
    	rescue RuntimeError => error
    		false
    	end

    	#defining the get and delete methods
    	['get', 'delete'].each do |name|
    		define_method name do |uri|
    			response = request(Net::HTTP.const_get(name.capitalize).new(uri)).body
    			JSON.parse(response)
    		end
    	end

    	def get_database_info(db_name)
    		get("/#{db+name}/")	
    	end

      def pull_all_design_docs(db_name)
        pull_all_doc_ids(db_name).map { get_document(db_name, id) if id[0,7] == "_design" }
      end

    	def pull_all_doc_ids(db_name)
        get("/#{db_name}/_all_docs")["rows"].map { |doc| doc["id"] }
    	end

    	def all_docs_from_database(db_name)
    	  pull_all_doc_ids(db_name).map { |id| Data::CouchDocument.new(get("/#{db_name}/#{id}")) }
    	end

    	def get_document(db_name, id)
    		document = Data::CouchDocument.new(get("/#{db_name}/#{id}"))
    	end

    	def delete_document(db_name, id)
    		delete("/#{db_name}/#{id}")
    	end

      # Haven't decided whether PUT/POST should take a CouchDocument or a JSON string.
    	def put( uri, json = nil )
    		#TODO - make this private
    		req = Net::HTTP::Put.new(uri)
    		req["content-type"] = "application/json"
    		req.body = json unless json == nil
    		JSON.parse(request(req).body)
    	end
  	
    	def post(uri, json = nil)
    	  # couch uses POST for new documents and gives them an ID
    	  req = Net::HTTP::Post.new(uri)
    	  req["content-type"] = "application/json"
    	  req.body = json unless json == nil
    	  JSON.parse(request(req).body)
    	  #TODO - return success more meaningfully maybe?
  	  end
  	
  	  def pull_document(db_name, document)
    		document = Data::CouchDocument.new(get("/#{db_name}/#{id}"))  	    
	    end
  	
    	def push_document(db_name, document)
    	  raise TypeError unless document.class == Data::CouchDocument
    	  raise JSON::GeneratorError unless document.valid?
    	  if document["_rev"]
    	    put("/#{db_name}/#{document._id}?rev=#{document._rev}/", document.to_json)
  	    else
  	      post("/#{db_name}/", document.to_json)
  	    end
  	  end

    	def create_db(db_name)
    		put("/#{db_name}/")
    	end
    	def delete_db(db_name)
    		delete("/#{db_name}/")
    	end

    	def UUID
    		get('/_uuids/')['uuids'][0]
    	end

    	private

    	def handle_error(req, res)
    		raise RuntimeError.new("#{res.code}:#{res.message}\nMETHOD:#{req.method}\nURI:#{req.path}\n#{res.body}")
    	end

    	def request(req)
    		res = Net::HTTP.start(@host, @port) { |http|
    		  req.basic_auth(@user, @password) if @user and @password
    		  http.request(req)
    		  }
    		unless res.kind_of?(Net::HTTPSuccess)
    			handle_error(req, res)
    		end
    		res
    	end
    end
  
  end
end