class InboundSms < ActiveRecord::Base
  belongs_to :thread_source, :class_name => "OutboundSms",
                         :foreign_key => "thread_source_id"
  
  belongs_to :group 
  belongs_to :action
  class << self
    
    def parse_incoming_sms(from, message)
      #user = User.find_by_mobile_no(from)
      action_keyword = parse_action(message)
      action = Action.find_by_keyword(action_keyword)  
      group_title = parse_group(message)
      group_title_avail = Group.exists?(group_title)
      add_to_inbound_sms(from,message,action)     
      puts "action #{action}...............#{group_title}"
      if action.nil? 
        if group_title_avail.nil? 
        group =  Group.exists?(action_keyword)
        puts "group exists---------------#{group.title}"
        unless group.nil?
          puts "group----------------is not nil"
          data = parse_data(message, 1)
          send_message_to_group(from, action_keyword, data)
        else
          OutboundSms.invalid_format(from)
          send_keywords_to_user(from)
        end      
        end
      else
        data = parse_data(message) 
        case action.name
          when "LIST_ALL_USERS"
          list(from,group_title)
          when "ADD_USER_TO_GROUP_FROM_ADMIN"
          add_user_to_group(from, group_title, data)
          when "INVITE_USERS_TO_GROUP"
          invite_users_to_group(from, group_title, data)
          when "SEND_MESSAGE_TO_GROUP"
          send_message_to_group(from, group_title, data)
          when "UNSUBSCRIBE"
          unsubscribe(from, group_title)
          when "REMOVE"
          remove(from, group_title, data)
          when "MUTE"
          mute(from,group_title)
          when "REJOIN"
          rejoin(from,group_title)
          when "HELP"
          send_keywords_to_user(from)
          
        else
          OutboundSms.invalid_format(from)
        end
      end
      
    end
    
    def add_to_inbound_sms(from,message,action)
      inbound_sms = InboundSms.new(:source=> from, :message=> message, :action=> action)
      inbound_sms.save
    end
    
    def parse_action(message, index = 0)
      action = message.split(" ")[index]
      action = action.downcase unless action.nil?
      action
    end
    
    def parse_group(message, index = 1)
      group_name = message.split(" ")[index]
      group_name = group_name.downcase unless group_name.nil?
      group_name
    end
    
    def parse_data(message, index = 2)
      message = (message.split(" ")[index..(message.length-1)])
      message.join(" ") unless message.nil?
    end
    
    def detokenize_message(token, message)
      message.split(token)[1]
    end
    
    def invite_users_to_group(from, group_title, numbers)
      mobile_nos = numbers.split(",")
      group = Group.exists?(group_title)    
      user = User.form_user(from)[:user]
      users = User.form_users(mobile_nos)            
      message = "#{from} has added you to the group #{group_title}"    
      members, invalid_members = User.slice_invalid_users(users)
      if group.nil?
        inviter_message = "Group #{group_title} does not exist"
        outbound_sms = OutboundSms.new(:from_no => SYSTEM_MOBILE_NO, :to_no => from, :message => inviter_message)
        outbound_sms.queue_sms
      else
        if group.has_member?(user)        
          if !members.nil? and !members.empty?
            members, existing_members = group.get_non_existing_members(members)
            if !members.nil? and !members.empty?
              inviter_message = "The valid numbers you provided were added to the group #{group_title} successfully"
              group.add_members(members)
              group.send_message(message, User.system_user, members)
            end
          end
          if !invalid_members.nil? and !invalid_members.empty?
            user.intimate_invalid_members(invalid_members)
          end
          if !existing_members.nil? and !existing_members.empty?
            user.intimate_existing_members(existing_members, group_title)
          end
        else       
          inviter_message = "You are not authorized to invite a member to the group #{group_title}"
        end
        unless inviter_message.nil?
          users = []
          group.send_message(inviter_message, User.system_user, users<<user)
      end
    end
    
    
  end

  def add_user_to_group(from, group_title, numbers)
    mobile_nos = numbers.split(",")        
    user = User.form_user(from)[:user]
    if Group.user_already_created_same_group?(user, group_title)
      message = "You already created a group with name #{group_title}"
      user.send_message(message)
    else
      group = Group.exists?(group_title)        
      users = User.form_users(mobile_nos) 
          
      members, invalid_members = User.slice_invalid_users(users)    
      if !group.nil? and group.has_admin?(user) and !members.nil? and !members.empty? 
        
        members, existing_members = group.get_non_existing_members(members)
        if !members.nil? and !members.empty?        
          admin_message = "The valid numbers you provided were added to the group #{group_title} successfully with title #{group.title}"
          group.add_members(members)
          send_keywords_to_user(from)
        end
      elsif group.nil?     
        group = Group.create_group_for_user(user, group_title, members)
        admin_message = "The group #{group_title} was created with #{group.title} and the valid numbers you provided were added"    
        send_keywords_to_user(from)
      end
      if !members.nil? and !members.empty?
        message = "#{from} has added you to the group with title #{group.title}"
        group.contact_admin(admin_message)
        group.send_message(message, User.system_user, members)
      end
      if !invalid_members.nil? and !invalid_members.empty?
        user.intimate_invalid_members(invalid_members)
      end
      if !existing_members.nil? and !existing_members.empty?
        user.intimate_existing_members(existing_members, group_title)
      end
    end    
  end
  
  def send_message_to_group(from, group_title, message)
    group = Group.exists?(group_title)
    user = User.exists?(from)
    if !user.nil? and !group.nil?
      group.send_message(message, user)
    else      
      message = user.nil? ? "You are not registered with us" : "Invalid Group"
      outbound_sms = OutboundSms.new(:from_no => SYSTEM_MOBILE_NO, :to_no => from, :message => message)
      outbound_sms.queue_sms
    end
  end
  
  def unsubscribe(from, group_title)
    group = Group.exists?(group_title)
    user = User.exists?(from)
    if !user.nil? and !group.nil?
      if group.has_member?(user)
        group.kick(user)
        message="You are successfully unsubscribed from the group #{group_title}"
      else
        message = "You are not a member of #{group_title} to unsubscribe"
      end
    else      
      message = user.nil? ? "You are not registered with us in any of the group" : "Group with title #{group_title} does not exist"      
    end
    outbound_sms = OutboundSms.new(:from_no => SYSTEM_MOBILE_NO, :to_no => from, :message => message)
    outbound_sms.queue_sms
  end
  
  def remove(from, group_title, number)
    group = Group.exists?(group_title)
    admin = User.exists?(from)
    user = User.exists?(number)
    is_admin = group.has_admin?(admin)
    if admin.nil? or !is_admin
      message = "You are not a valid admin for the group with title #{group_title}"
    elsif group.nil?
      message = "Group with title #{group_title} does not exist"
    elsif user.nil?
      message = "No user exists with mobile number #{number}"
    else
      if group.has_member?(user)
        group.kick(user)
        message = "User #{number} successfully removed from the group #{group_title}"
      else
        message="User #{number} is not a member of group #{group_title}"
      end      
    end      
      outbound_sms = OutboundSms.new(:from_no => SYSTEM_MOBILE_NO, :to_no => from, :message => message)
      outbound_sms.queue_sms    
  end   

  def mute(from,group_title)
    user = User.exists?(from)    
    group=Group.exists?(group_title)
     unless group.nil?          
        membership = group.active_membership(user)
        unless membership.nil?
          group.mute_membership(membership)
          message = "You are successfully muted from the group #{group_title}"
        else
          message = "You are currently not an active member of the group #{group_title}"
        end                      
     else
      message = "Group with title #{group_title} does not exist"
    end    
    outbound_sms = OutboundSms.new(:from_no => SYSTEM_MOBILE_NO, :to_no => from, :message => message)
    outbound_sms.queue_sms     
  end
 
  def rejoin(from,group_title)
    user = User.exists?(from)    
    group=Group.exists?(group_title)
     unless group.nil?      
        membership = group.muted_membership(user)
        unless membership.nil?
          group.unmute_membership(membership)
          message = "You are successfully unmuted from the group #{group.title}"
        else
          message = "You are currently not a muted member of the group #{group.title}"
        end     
    else
      message = "Group with title #{group_title} does not exist"
    end    
    outbound_sms = OutboundSms.new(:from_no => SYSTEM_MOBILE_NO, :to_no => from, :message => message)
    outbound_sms.queue_sms     
  end     

  def list(from,group_title)
    user = User.exists?(from)
    unless user.nil?
        group=Group.exists?(group_title)
         unless group.nil?
          list = group.get_list(user)
          if list.nil?
            message = "No users Found in your group #{group.title}" 
          elsif list==false
            message = "Access denied for this group #{group.title}" 
          else
            message = "Users in #{group.title} group #{list}"
          end
        else
          message = "Group with title #{group_title} does not exist"
        end
    else
      message = "Access denied for this group #{group_title}" 
    end
    outbound_sms = OutboundSms.new(:from_no => SYSTEM_MOBILE_NO, :to_no => from, :message => message)
    outbound_sms.queue_sms 
  end  
  
   def send_keywords_to_user(from)
    keywords = Action.get_keywords
    puts "list of keywords #{keywords}"
    if !keywords.nil?
      message = "Please use these keywords for messaging #{keywords}"
    end
    outbound_sms = OutboundSms.new(:from_no => SYSTEM_MOBILE_NO, :to_no => from, :message => message)
    outbound_sms.queue_sms    
  end
    
  end
  
  def reply_to_user(message)
    
  end
  def broadcast_to_target
    outbound_sms = OutboundSms.new(:to_no => self.intended_to, :message => self.message, :thread_source => self, :token => OutboundSms.generate_token)
    outbound_sms.queue_sms
  end
  
  
end
