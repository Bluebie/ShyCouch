module ShyCouch

  module Data
  
    class CouchDocument < Hash
      class << self
        # allows instance.class.requirements to be called
        attr_accessor :requirements
      end
    
      def initialize(hash={})
        # Assumes that the "kind" is the class name unless explicitly stated otherwise
        # TODO - maybe just force it to be the class name no matter what tbh
        hash["kind"] = self.class.to_s unless hash["kind"]
        merge!(hash)
        raise TypeError unless valid?
        # super(hash)
      end
    
      # def initialize(hash=nil, requirements)
      #   @requirements = requirements
      #   merge!(hash) if hash
      #   raise TypeError unless valid? #TODO - should raise a more specific and useful error
      # end
    
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
        database = $couchdb unless database
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
    
      def method_missing(m, *a)
        # Makes the object behave as if the hash keys are instance properties with attr_accessors
        # Had a dozen lines or so for this and found a one-line implementation of the same thing in Camping.
        m.to_s =~ /=$/ ? self[$`] = a[0] : a == [] ? self[m.to_s] : super
      end
    
      def respond_to?(method)
        # so that testing for whether it responds to a method is equivalent to testing for the existence of a key
        self.key?(method.to_s) ? true : super
      end
    
    end

    class Design < CouchDocument
      # this is used to manage design documents
      # In practise, the Controllers should be a list of classes corresponding to design documents

      def map(&block);end

      def reduce(&block);end

      def push;end #must override push in order to set the ID
    end

  end

end