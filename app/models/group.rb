class Group < ActiveRecord::Base
  belongs_to :company
  has_many :memberships
  has_many :members, :through => :memberships, :source => :user, :conditions => 'accepted_at IS NOT NULL'
  has_many :pending_members, :through => :memberships, :source => :user, :conditions => 'accepted_at IS NULL'
  has_many :active_members, :through => :memberships, :source => :user, :conditions => ['mute = ?', false]
  has_many :inactive_members, :through => :memberships, :source => :user, :conditions => ['mute = ?',true]
  has_many :mods, :through => :memberships, :source => :user, :conditions => ['admin_role = ?', true]
  has_many :active_mods, :through => :memberships, :source => :user, :conditions => ['admin_role = ? AND mute = ?', true, false]
  has_many :inbound_sms 
  has_many :outbound_sms
  
  RANDOM_UNIQUE_TITLE_DIGITS = 3
  
  class << self
    
    def exists?(name)
      find_by_title(name.downcase)
    end
    
    def user_already_created_same_group?(user, actual_name)
      group = Group.find_by_actual_name(actual_name, :joins=>"INNER JOIN memberships m on m.group_id = groups.id AND m.user_id = #{user.id} AND m.admin_role=1")      
      !group.nil?
    end
    
    def create_group(name)
      group = Group.new(:title=>name, :company=>Thread.current[:current_company])
      group.save
      group
    end
    
    def create_group_for_user(admin, name, members)      
      title = Group.generate_unique_name(name)      
      group = Group.new(:title=>title, :company=>Thread.current[:current_company], :actual_name=>name.downcase)      
      group.save!
      group.add_admin(admin)
      group.add_members(members)
      group
    end
    
    def create_if_not_exists(name)
      title = Group.generate_unique_name(name)
      group =  exists?(name)
      if group.nil?
        group = create_group(name)
      end
      group
    end  
    
    def generate_unique_name(name)
    count = Group.count(:all,:conditions=>['actual_name = ?', name.downcase])
    digits = count.to_s.size
    digits = digits > RANDOM_UNIQUE_TITLE_DIGITS ? digits : RANDOM_UNIQUE_TITLE_DIGITS
    name+count.to_s.rjust(digits,'0')
  end
  end
  
  def membership(user)
    Membership.find(:first, :conditions => ['group_id = ? AND user_id = ?', self.id, user.id])
  end  
  
  def accept_member(user)
    self.membership(user).update_attribute(:accepted_at, Time.now)
  end
  
  def pending_and_accepted_members
    self.pending_members + self.members
  end
  
  def kick(user)
    self.membership(user).destroy #if user.is_member_of?(self)
  end
  
  def mods_online
    self.mods.find(:all, :conditions => ['users.updated_at > ?', 50.seconds.ago])
  end
  
  def members_online
    self.members.find(:all, :conditions => ['users.updated_at > ?', 70.seconds.ago])
  end
  
  def members_offline
    self.members - self.members_online
  end
  
  def has_member?(user)    
    self.members.to_ary.include?(user)
  end
  
  def has_admin?(user)    
    self.mods.to_ary.include?(user)
  end
  
  def has_active_admin?(user)    
    self.active_mods.to_ary.include?(user)
  end
  
  def active_membership(user)
    user.nil? ? nil : Membership.find(:first, :conditions => ['group_id = ? AND user_id = ? AND mute = ?', self.id, user.id, false])
  end
  
  def muted_membership(user)
    user.nil? ? nil : Membership.find(:first, :conditions => ['group_id = ? AND user_id = ? AND mute = ?', self.id, user.id, true])
  end
  
  def has_active_membership?(user)
    !self.active_membership(user).nil?
  end
  
  def add_members(users)
    users.each do |user|
      self.add_member(user)
    end
  end
  
  def add_member(user)
    membership = Membership.new(:group=>self, :user=>user,:accepted_at=>Time.now)
    membership.save
  end
  
  def add_admin(user)
    membership = Membership.new(:group=>self, :user=>user, :admin_role=>true,:accepted_at=>Time.now)
    membership.save
  end
  
  def send_message(message, from, members=nil)
    outbounds_sms = []
    if members.nil?
      members = self.active_members.to_ary
      members.delete(from)
    end
    if !from.name.nil? and !from.name.empty?
        message = "[#{from.name}@#{self.title}]:#{message}"
    elsif from.mobile_no!= SYSTEM_MOBILE_NO
      message = "[#{from.mobile_no}@#{self.title}]:#{message}"
    end
    members.each do |member|
      outbound_sms = OutboundSms.new(:from_no=>from.mobile_no, :to_no=>member.mobile_no, :message=>message, :group=>self)
      outbounds_sms << outbound_sms
    end
    OutboundSms.queue_bulk(outbounds_sms)
  end  
 
   def get_non_existing_members(members)
     existing_members = []
     group_members = self.members
     group_members.each do |group_member|
       if members.include?(group_member)
         existing_members << group_member
         members.delete(group_member)
       end
     end
     return members, existing_members
   end
 
  def get_list(user)    
    self.has_member?(user) ? self.members.collect{|user| user.mobile_no}.join(',').to_s : false 
  end
  
  def contact_admin(message, user=nil)
      from_user = user.nil? ? User.system_user : user
      admin = self.mods.to_ary[0]      
      outbound_sms = OutboundSms.new(:from_no=>from_user.mobile_no, :to_no=>admin.mobile_no, :message=>message, :group=>self)
      outbound_sms.queue_sms
  end
  
  def mute_membership(membership)
    unless membership.nil?
      membership.mute=true
      membership.muted_at=Time.now
      membership.save!
    end
  end
  
  def unmute_membership(membership)
    unless membership.nil?
      membership.mute=false
      membership.save
    end
  end
end
