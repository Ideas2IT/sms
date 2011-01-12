class InboundSms < ActiveRecord::Base
  belongs_to :thread_source, :class_name => "OutboundSms",
                         :foreign_key => "thread_source_id"
  class << self
    
    def parse_incoming_sms(from, message)
      token = InboundSms.parse_token(message)      
      unless token.nil?
        puts "token......"
        detokenized_message = InboundSms.detokenize_message(token, message)
        source_message = OutboundSms.find_source_by_token(token)
        unless source_message.nil?
          inbound_sms = InboundSms.new(:source=>from, :message=>detokenized_message, :token=>token, :intended_to=>source_message.from, :thread_source=>source_message)
          inbound_sms.save
          inbound_sms.broadcast_to_target
        end
      end
#      unless User.get_if_admin(from).nil?
#        
#      end
    end
    
    def parse_token(message)
    message.split(" ")[1]
  end
  
  def detokenize_message(token, message)
    message.split(token)[1]
  end
    
  end
  
  def reply_to_user(message)
    
  end
  def broadcast_to_target
    outbound_sms = OutboundSms.new(:to => self.intended_to, :message => self.message, :thread_source => self, :token => OutboundSms.generate_token)
    outbound_sms.queue_sms
  end
  
  
end
