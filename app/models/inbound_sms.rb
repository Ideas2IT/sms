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
      data = parse_data(message)
      case action.name
        when "LIST_ALL_USERS"
          list(from,group_title)
        when "ADD_USER_TO_GROUP_FROM_ADMIN"
          add_user_to_group(from, group_title, data)
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
      end
    end
    
  def parse_action(message)
    message.split(" ")[0].downcase
  end
  
  def parse_group(message)
    message.split(" ")[1].downcase
  end
  
  def parse_data(message)
    message.split(" ")[2]
  end
  
  def detokenize_message(token, message)
    message.split(token)[1]
  end  

  def add_user_to_group(from, group_title, numbers)
    mobile_nos = numbers.split(",")
    group = Group.exists?(group_title)    
    user = User.form_user(from)
    members = User.form_users(mobile_nos)
    message = "#{from} has added you to the group #{group_title}"
    if !group.nil? and group.has_admin?(user)
      puts "coming"
      members = group.get_non_existing_members(members)
      group.add_members(members)
      group.send_message(message, User.system_user, members)
    elsif group.nil?
      puts "coming elsif"
      group = Group.create_group_for_user(user, group_title, members)
      group.send_message(message, User.system_user, members)
    else
      puts "coming else #{group.nil?}--------#{group.has_admin?(user)} ===========>"
    end    
  end
  
  def send_message_to_group(from, group_title, message)
    group = Group.exists?(group_title)
    user = User.exists?(from)
    if !user.nil? and !group.nil?
      group.send_message(message, user)
    else      
      message = user.nil? ? "You are not registered with us" : "Invalid Group"
      outbound_sms = OutboundSms.new(:from => SYSTEM_MOBILE_NO, :to => from, :message => message)
      outbound_sms.queue_sms
    end
  end
  
  def unsubscribe(from, group_title)
    group = Group.exists?(group_title)
    user = User.exists?(from)
    if !user.nil? and !group.nil?
      if group.has_member?(user)
        group.kick(user)
        message="You are successfully removed from the group #{group.title}"
      else
        message = "You are not a member to do so"
      end
    else      
      message = user.nil? ? "You are not registered with us" : "Invalid Group"
      
    end
    outbound_sms = OutboundSms.new(:from => SYSTEM_MOBILE_NO, :to => from, :message => message)
    outbound_sms.queue_sms
  end
  
  def remove(from, group_title, number)
    group = Group.exists?(group_title)
    admin = User.exists?(from)
    user = User.exists?(number)
    is_admin = group.has_admin?(admin)
    if !admin.nil? and !group.nil? and !user.nil?
      group.kick(user) #if is_admin
    else      
      message = (user.nil? or is_admin==false) ? "You are not a valid admin for th egroup or the user does not exist" : "Invalid Group"
      outbound_sms = OutboundSms.new(:from => SYSTEM_MOBILE_NO, :to => from, :message => message)
      outbound_sms.queue_sms
    end
  end   

  def mute(from,group_title)
    user = User.exists?(from)
    unless user.nil?
        group=Group.exists?(group_title)
         unless group.nil?
          if group.has_member?(user)
            membership = Membership.find(:first,:conditions=>['user_id = ? and group_id = ?',user.id,group.id])
            puts "mure...#{membership.inspect}"
            membership.mute = true
            membership.save!
            message = "Successfully muted for the group #{group_title}"
          else
            message = "Access denied for this group #{group_title}" 
          end
        else
          message = "Group #{group_title} not exists"
        end
    else
      message = "Access denied for this group #{group_title}" 
    end
    outbound_sms = OutboundSms.new(:from => SYSTEM_MOBILE_NO, :to => from, :message => message)
    outbound_sms.queue_sms     
  end
 
  def rejoin(from,group_title)
    user = User.exists?(from)
    unless user.nil?
        group=Group.exists?(group_title)
         unless group.nil?
          if group.has_member?(user)
            membership = Membership.find(:first,:conditions=>['user_id = ? and group_id = ?',user.id,group.id])
            membership.mute = false
            membership.save!
            message = "Successfully unmuted for the group #{group_title}"
          else
            message = "Access denied for this group #{group_title}" 
          end
        else
          message = "Group #{group_title} not exists"
        end
    else
      message = "Access denied for this group #{group_title}" 
    end
    outbound_sms = OutboundSms.new(:from => SYSTEM_MOBILE_NO, :to => from, :message => message)
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
          message = "Group #{group_title} not exists"
        end
    else
      message = "Access denied for this group #{group_title}" 
    end
    outbound_sms = OutboundSms.new(:from => SYSTEM_MOBILE_NO, :to => from, :message => message)
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
