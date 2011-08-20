module ShyCouch
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
end