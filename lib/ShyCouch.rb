# July 2011
# This is a small Ruby layer for working with CouchDB
# Built primarily to allow Camping apps to use CouchDB for data persistence 
# ShyRubyJS is library used to build map and reduce functions from Ruby blocks

require 'net/http'
require 'json'
require 'resolv'
require 'shyrubyjs'

module Kernel
  def shycouch
    $database = ShyCouch::Connection.Create
  end
end

module ShyCouch
  
  attr_accessor :database
  
  class Connection
    def self.Create(settings=nil)
      settings = $settings unless settings
      database = CouchDBAPI.new(settings["db"]["host"], settings["db"]["port"], settings["db"]["name"], settings["db"]["user"], settings["db"]["password"])
      puts database.connect unless database.connect["ok"]
      database.create unless database.on_server?
      return database
    end
    
    def push_generic_views
      #TODO 
    end
  end

  
  module Data
    class Model < Hash
      # takes hash that will be the document contents as well as an array of expected keys for validation
      # todo - enforce keys that work as attrs

      def initialize(hash=nil, requirements)
        @requirements = requirements
        merge!(hash) if hash
        raise TypeError unless valid? #TODO - should raise a more specific and useful error
      end

      def method_missing(name, *args)
        # Makes the object behave as if the hash keys are instance properties with attr_accessors
        if name.to_s
          if name[name.length-1] == "="
            key = name[0, name.length-1]
            if self.key?(key)
              self[key] = args
              return args
            end
          else
            return self[name.to_s] unless !self[name.to_s]
          end
        end
        super
      end
      
      def respond_to?(method)
        # so that testing for whether it responds to a method is equivalent to testing for the existence of a key
        return true if self.key?(method.to_s)
        super
      end
    end
    
    class CouchDocument < Model
      class << self
        # allows instance.class.requirements to be called
        attr_accessor :requirements
      end
      
      def initialize(hash={})
        # Assumes that the "kind" is the class name unless explicitly stated otherwise
        # TODO - maybe just force it to be the class name no matter what tbh
        hash["kind"] = self.class.to_s unless hash["kind"]
        super(hash, @requirements)
      end
      
      def self.all
        database = CouchDatabase.new($settings)
        database.get()
      end
      
      def self.requires(*requirements)
        @requirements = requirements
      end
      
      def add_key(key, value=nil)
        # The attr value assignment operator has been overriden, but it checks for the existence of a key.
        # And therefore the user has to explicitly call this method first.
        self[key] = value
      end
      
      def attr_keys
        # returns the keys for all the attrs that aren't the id or rev
        attr_keys = []
        self.map { |k,v|
          attr_keys << k unless k == "_id" or k == "_rev"
        }
        return attr_keys
      end
      
      def _requirements
        #TODO - hm
        return self.class.requirements
      end
      
      def pull(database=nil)
        database = $database unless database
        new_doc = database.pull_document(self)
        if new_doc
          self.clear
          self.merge! new_doc
        end
      end
      
      def push(database = nil)
        # assumes $database unless it receives a database argument
        database = $database unless database
        res = database.push_document(self)
        self["_id"] = res["id"]
        self["_rev"] = res["rev"]
        return res
      end
      
      def valid?; to_json ? true : false; end
      
      def to_json
        JSON::generate(self)
      rescue JSON::GeneratorError
        false
      end
    end
  end

  module Fields
    #TODO - lightweight validation framework 
    
    class Email_Addr < String
      def valid?
        # Valid if: one and only one '@'; at least one "." after the '@'; an mx record can be resolved at the domain
        valid_address? and valid_domain?
      end
      def valid_address?
        self.split("@").length == 2 and self.split("@")[1].split(".").length >= 2
        
      end
      def valid_domain?
        domain = self.match(/\@(.+)/)[1]
        Resolv::DNS.open { |dns| dns.getresources(domain, Resolv::DNS::Resource::IN::MX) }.size > 0 ? true : false
        rescue Resolv::ResolvError
          false
      end
    end
  end

  #TODO - split this stuff into modules too
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