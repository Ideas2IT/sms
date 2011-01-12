class OutboundSms < ActiveRecord::Base
  belongs_to :thread_source, :class_name => "InboundSms",
                         :foreign_key => "thread_source_id"
  class << self
    
   def find_source_by_token(token)
     find_by_token(token)
   end
    
   def contact_admin(mobile_no, message)
     unless User.form_user(mobile_no).nil?
       current_company = Thread.current[:current_company]
       puts "admin.......#{current_company.id}"
       admin_no = (current_company.admin_user).mobile_no
       token = generate_token
       tokenized_message = tokenize_message(token, message)
       outbound_sms = OutboundSms.new(:from => mobile_no, :to => admin_no, :token => token, :message => tokenized_message)
       outbound_sms.queue_sms    
     end
   end    
    
    def generate_token
      rand(36**8).to_s(36)
    end
    
    def tokenize_message(token, message)
      "To reply type, MD "+token+" <reply>.." +message
    end
    
    def jeno_deliver_sms(mobile_no, message)
      query = "INSERT INTO jenooutbox (mobilenumber,message) VALUES('#{ mobile_no }','#{message}');"
      begin
        ActiveRecord::Base.connection.execute(query)
        return true
      rescue Exception => e
        return false
      end      
    end
    
  end
  
  def queue_sms
    if OutboundSms.jeno_deliver_sms(self.to, self.message)
          self.gateway_delivered = true
    end 
    self.save
  end
  
end
