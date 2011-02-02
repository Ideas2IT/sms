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
      group = Group.exists?(group_title) unless group_title.nil?
      if action.nil? 
        if group.nil? 
          group =  Group.exists?(action_keyword) 
          temp_action = Action.find_by_keyword("msg")
          if !group.nil?
            add_to_inbound_sms(from,message,temp_action,group)
            data = parse_data(message, 1)
            send_message_to_group(from, action_keyword, data)
          else
            OutboundSms.invalid_format(from)
            add_to_inbound_sms(from,message)
          end      
        end
      else
        add_to_inbound_sms(from,message,action,group) 
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
          when "GROUPS"
          find_group(from)
          when "NICK"
          add_nickname(from,message)
          when "INACTIVE"
          get_inactive_members(from,group)
          when "HISTORY"
          get_history_of_muted_user(from,group)
        else
          OutboundSms.invalid_format(from)
        end
      end
      
    end
    
    def find_group(from)
      user = User.exists?(from)   
      if !user.nil?
        user_admin = user.admin_groups.collect{|group| group.title}.join(',').to_s
        user_non_admin = user.non_admin_groups.collect{|group| group.title}.join(',').to_s
        message = "As admin your groups are #{user_admin} and As a member your groups are #{user_non_admin},You have created #{user_admin}, You are member of #{user_non_admin}."
      else
        message = USER_DOES_NOT_EXISTS
      end    
      outbound_sms = OutboundSms.new(:from_no => SYSTEM_MOBILE_NO, :to_no => from, :message => message)
      outbound_sms.queue_sms      
    end
    
    def add_nickname(from,message)
      user = User.exists?(from)   
      unless user.nil?
        user_name = parse_group(message)
        user.name = user_name
        user.save!
        message = "Nick name successfully added"
      end
      outbound_sms = OutboundSms.new(:from_no => SYSTEM_MOBILE_NO, :to_no => from, :message => message)
      outbound_sms.queue_sms
    end
    
    def get_inactive_members(from,group)
      user = User.exists?(from)   
      unless user.nil?
        if !group.nil?
          inactive_members = group.inactive_members.collect{|user| user.mobile_no}.join(',').to_s
          if inactive_members.empty?
            message = "There are no inactive members in your group"
          else
            message = "Inactive members of the group #{group.title} are #{inactive_members}"        
          end
        else
          message = "please enter valid group name"
        end
        
      end
      outbound_sms = OutboundSms.new(:from_no => SYSTEM_MOBILE_NO, :to_no => from, :message => message)
      outbound_sms.queue_sms
    end
    def get_history_of_muted_user(from,group)
      user = User.exists?(from)
      unless user.nil?
        
      end
    end
    def add_to_inbound_sms(from,message,action=nil,group=nil)
      if !group.nil? 
        inbound_sms = InboundSms.new(:source=> from, :message=> message, :action=> action, :group_id=>group.id)
      else
        inbound_sms = InboundSms.new(:source=> from, :message=> message)
      end
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
      existing_users = User.find(:all,:conditions=>["mobile_no in (?)",mobile_nos])
      existing_mob = existing_users.collect{|user| user.mobile_no}
      new_mob = mobile_nos - existing_mob
      user = User.exists?(from).nil? ? User.form_user(from)[:user] : User.exists?(from)
      new_users = User.form_users(new_mob)
      new_members, invalid_members = User.slice_invalid_users(new_users)
      members = existing_users + new_members
      message_for_existing = "#{from} has invited you to the group #{group_title} #{UNSUB_MESSAGE} #{HELP_MESSAGE}"
      message_for_new ="#{WELCOME_MESSAGE_MEMBERS} #{from} has invited you to the group #{group_title} Reply message to #{SYSTEM_MOBILE_NO} to message everybody in the group. #{message_for_existing}"
      if group.nil?
        inviter_message = GROUP_DOES_NOT_EXISTS
        outbound_sms = OutboundSms.new(:from_no => SYSTEM_MOBILE_NO, :to_no => from, :message => inviter_message)
        outbound_sms.queue_sms
      else
        if group.has_active_membership?(user)        
          if !members.nil? and !members.empty?
            members, existing_members = group.get_non_existing_members(members)
            if !members.nil? and !members.empty?
              inviter_message = "The valid numbers you provided were added to the group #{group_title} successfully"
              group.add_members(members)
              group.send_message(message_for_existing, User.system_user, existing_users)
              group.send_message(message_for_new, User.system_user, new_members)
            end
          end
          if !invalid_members.nil? and !invalid_members.empty?
            user.intimate_invalid_members(invalid_members)
          end
          if !existing_members.nil? and !existing_members.empty?
            user.intimate_existing_members(existing_members, group_title)
          end
        else       
          inviter_message = "You are not an active member to invite a member to the group #{group_title}"
        end
        unless inviter_message.nil?
          users = []
          group.send_message(inviter_message, User.system_user, users<<user)
      end
    end
    
    
  end

  def add_user_to_group(from, group_title, numbers)
    mobile_nos = numbers.split(",")        
    user = User.exists?(from).nil? ? User.form_user(from)[:user] : User.exists?(from)
    existing_users = User.find(:all,:conditions=>["mobile_no in (?)",mobile_nos])
    existing_mob = existing_users.collect{|user| user.mobile_no}
    new_mob = mobile_nos - existing_mob
    message_for_existing = "#{from} has invited you to the group #{group_title} #{UNSUB_MESSAGE} #{HELP_MESSAGE}"
    message_for_new ="#{WELCOME_MESSAGE_MEMBERS} #{from} has invited you to the group #{group_title} Reply message to #{SYSTEM_MOBILE_NO} to message everybody in the group. #{message_for_existing}"
    if Group.user_already_created_same_group?(user, group_title)
      message = "You already created a group with name #{group_title}. Creation not possible again"
      user.send_message(message)
    else
      group = Group.exists?(group_title)        
      new_users = User.form_users(new_mob) 
      new_members, invalid_members = User.slice_invalid_users(new_users) 
      members = existing_users + new_members
      if !group.nil? 
        if group.has_active_admin?(user) 
          if !members.nil? and !members.empty?
            members, existing_members = group.get_non_existing_members(members)
            if !members.nil? and !members.empty?        
              admin_message = "The valid numbers you provided were added to the group #{group_title} successfully with title #{group.title}"
              group.add_members(members)
              send_keywords_to_user(from)
            end
          end
        else
          admin_message = "You are not a valid active admin of the group #{group_title}"
        end
      else     
        group = Group.create_group_for_user(user, group_title, members)
        admin_message = "The group #{group_title} was created with #{group.title} and the valid numbers you provided were added"    
        send_keywords_to_user(from)
      end
      if !members.nil? and !members.empty?
        group.contact_admin(admin_message)
        group.send_message(message_for_existing, User.system_user, existing_users)
        group.send_message(message_for_new, User.system_user, new_members)
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
      if group.has_active_membership?(user)
        group.send_message(message, user)
      else
        reply_message = "You are not an active member of the group #{group_title}"
      end      
    else      
      reply_message = user.nil? ? "Sorry. You are not authorized to perform (messaging)" : GROUP_DOES_NOT_EXISTS      
    end
    unless reply_message.nil?
      outbound_sms = OutboundSms.new(:from_no => SYSTEM_MOBILE_NO, :to_no => from, :message => reply_message)
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
        message = "You are not authorized to perform (unsubscription)"
      end
    else      
      message = user.nil? ? "Sorry. You are not authorized to perform (unsubscription)" : GROUP_DOES_NOT_EXISTS      
    end
    outbound_sms = OutboundSms.new(:from_no => SYSTEM_MOBILE_NO, :to_no => from, :message => message)
    outbound_sms.queue_sms
  end
  
  def remove(from, group_title, number)
    group = Group.exists?(group_title)
    admin = User.exists?(from)
    user = User.exists?(number)
    is_admin = group.has_active_admin?(admin)
    if admin.nil? or !is_admin
      message = "You are not authorized to (rmv: remove a member) from #{group_title}"
    elsif group.nil?
      message = GROUP_DOES_NOT_EXISTS
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
      message = GROUP_DOES_NOT_EXISTS
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
      message = GROUP_DOES_NOT_EXISTS
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
            message = "You are not a member of this group :#{group.title}. Please request a member to invite you" 
          else
            message = "Users in #{group.title} group #{list}"
          end
        else
          message = GROUP_DOES_NOT_EXISTS
        end
    else
      message = "Sorry. You are not authorized to perform (list). " 
    end
    outbound_sms = OutboundSms.new(:from_no => SYSTEM_MOBILE_NO, :to_no => from, :message => message)
    outbound_sms.queue_sms 
  end  
  
   def send_keywords_to_user(from)
    keywords = Action.get_keywords    
    if !keywords.nil?
      message = "Please use the format for messaging #{keywords}"
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
