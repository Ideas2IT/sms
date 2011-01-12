class InboundSms < ActiveRecord::Base
  belongs_to :thread_source, :class_name => "OutboundSms",
                         :foreign_key => "thread_source_id"
                         
  belongs_to :group, :action
  class << self
    
    def parse_incoming_sms(from, message)
      #user = User.find_by_mobile_no(from)
      action_keyword = parse_action(message)
      action = Action.find_by_keyword(action_keyword)
      group_title = parse_group(message)
      case action.name
        when "LIST"
          list(from,group_title)
          
      end
    end
    
  def parse_action(message)
    message.split(" ")[0]
  end
  
  def parse_group(message)
    message.split(" ")[1]
  end
  
  def detokenize_message(token, message)
    message.split(token)[1]
  end
   
  def list(from,group_title)
    user = User.exists?(from)
    unless user.nil?
        group=Group.exists?(group_title)
         unless group.nil?
          list = group.get_list(user)
          if list.nil? or list.empty? 
            message = "No users Found in your group #{group.title}" 
          elsif list==false
            message = "Access denied for this group #{group.title}" 
          else
            message = "Users in #{group.title} group #{list}"
          end
        else
          message = "Group #{group_title} not exists"
        end
    else
      message = "Access denied for this group #{group_title}" 
    end
    outbound_sms = OutboundSms.new(:from => SYSTEM_MOBILE_NO, :to => user.mobile, :message => message)
    outbound_sms.queue_sms 
  end  
    
  end
  
  def reply_to_user(message)
    
  end
  def broadcast_to_target
    outbound_sms = OutboundSms.new(:to => self.intended_to, :message => self.message, :thread_source => self, :token => OutboundSms.generate_token)
    outbound_sms.queue_sms
  end
  
  
end
