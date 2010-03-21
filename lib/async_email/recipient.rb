module AsyncEmail #:nodoc:
  
  class Recipient < ActiveRecord::Base #:nodoc:
    set_table_name :ae_recipients

    class << self
    
      def add_to(message)
        message.send(recipient_type, addresses)
      end
    
      def recipient_type
        self.to_s.demodulize.downcase
      end

      def addresses
        all.map(&:email_address).join(",")
      end
    
    end
  end
  
end