class OutboundSms < ActiveRecord::Base
  belongs_to :thread_source, :class_name => "InboundSms",
                         :foreign_key => "thread_source_id"
                         
  belongs_to :group
  INVALID_FORMAT = "Please specify a proper message format"
  class << self
    
    def invalid_format(mobile_no)
      error_count = OutboundSms.count(:all,:conditions=>['to_no = ? AND message = ? AND created_at > ?', mobile_no,INVALID_FORMAT,10.minutes.ago]) 
      if error_count<2
        message = ""
        outbound_sms = OutboundSms.new(:from_no => User.system_user.mobile_no, :to_no => mobile_no,:message => INVALID_FORMAT)
        outbound_sms.queue_sms
      end
    end
    
   def find_source_by_token(token)
     find_by_token(token)
   end
   
   def queue_bulk(outbounds_sms)
       outbounds_sms.each do |outbound_sms|
         outbound_sms.queue_sms
       end
     end
    
   def contact_admin(mobile_no, message)
     unless User.form_user(mobile_no).nil?
       current_company = Thread.current[:current_company]
       admin_no = (current_company.admin_user).mobile_no
       token = generate_token
       tokenized_message = tokenize_message(token, message)
       outbound_sms = OutboundSms.new(:from_no => mobile_no, :to_no => admin_no, :token => token, :message => tokenized_message)
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
    if OutboundSms.jeno_deliver_sms(self.to_no, self.message)
          self.gateway_delivered = true
    end 
    self.save
  end
  
end
