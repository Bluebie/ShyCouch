module ShyCouch

  module Data
  
    class CouchDocument < Hash
      class << self
        # allows instance.class.requirements to be called
      end
      @@needs, @@suggests = [], []

      def initialize(hash={})
        # Assumes that the "kind" is the class name unless explicitly stated otherwise
        # TODO - maybe just force it to be the class name no matter what tbh
        hash["kind"] = self.class.to_s.split("::").last unless hash["kind"]
        merge!(hash)
        raise TypeError unless valid?
        # super(hash)
      end
    
      def self.all
        
      end
      
      def self.needs(*requirements)
        requirements.map { |requirement| @@needs << requirement } unless requirements.empty?
        return @@needs
      end
      
      def self.suggests(*suggestions)
        suggestions.map { |suggestion| @@suggests << suggestion } unless suggestions.empty?
        return @@suggests
      end
      
      def needs;self.class.needs; end
      def suggests; self.class.suggests; end
      
      def needs?(requirement)
        @@needs.include?(requirement) ? true : false
      end
      
      def suggests?(requirement)
        @@suggests.include?(requirement) ? true : false
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
        database ||= $couchdb
        new_doc = database.pull_document(self)
        if new_doc
          self.clear
          self.merge! new_doc
        end
      end
    
      def push(database = nil)
        database ||= $couchdb
        res = database.push_document(self)
        self["_id"] = res["id"] unless self["_id"]
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
    
    class View
      attr_accessor :map, :reduce, :name
      JS_MAP_FUNCTION_HEADER = "function ( doc ) { \n    "
      JS_REDUCE_FUNCTION_HEADER = "function(key, values, rereduce) { \n    "
      JS_FUNCTION_FOOTER = "}"
      
      def initialize(view_name, &block)
        #O TODO - oh dear this is a nightmare
        @parser = ShyRubyJS::ShySexpParser.new
        sexp_check = block.to_sexp
        sexp = block.to_sexp(:strip_enclosure=>true)

        # make sure the two blocks inside are calls to "map" and "reduce"

        @name = view_name.to_s        
        if sexp[0] == :block
          unless sexp_check[3][1][1][2] == :map and sexp_check[3][2][1][2] == :reduce
            raise ShyCouchError, "view must be called with map block and optional reduce block" 
          end
          [1,2].each { |num|
            2.times { sexp[num].delete_at(1) }
          }
          @map = JS_MAP_FUNCTION_HEADER + @parser.parse(sexp[1])[0] + JS_FUNCTION_FOOTER
          @reduce = JS_REDUCE_FUNCTION_HEADER + @parser.parse(sexp[2])[0] + JS_FUNCTION_FOOTER
        elsif sexp[0] == :iter
          raise ShyCouchError, "view must be called with map block and optional reduce block" unless sexp[1][2] == :map
          @map = JS_MAP_FUNCTION_HEADER + @parser.parse(sexp[3]) + JS_FUNCTION_FOOTER
        end
      end
      
      def as_hash
        h = {}
        h[@name] = {"map" => @map}
        h.merge!({"reduce" => @reduce}) if @reduce
        return h
      end
      
      def functions
        return {"map" => @map, "reduce" => @reduce}
      end
    end

    class Design < CouchDocument
      # this is used to manage design documents
      # In practise, the Controllers should be a list of classes corresponding to design documents
      
      def initialize(name, views=[])
        merge! "_id" => "_design/#{name.to_s}"
        @parser = ShyRubyJS::ShySexpParser.new
        h = {"views" => {}}
        views.each do |view|
          h["views"][view.name] = view.functions
        end
        merge! h
      end
    end

  end

end