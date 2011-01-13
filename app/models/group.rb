class Group < ActiveRecord::Base
  belongs_to :company
  has_many :memberships
  has_many :members, :through => :memberships, :source => :user, :conditions => 'accepted_at IS NOT NULL'
  has_many :pending_members, :through => :memberships, :source => :user, :conditions => 'accepted_at IS NULL'
  has_many :active_members, :through => :memberships, :source => :user, :conditions => ['mute = ?', false]
  has_many :mods, :through => :memberships, :source => :user, :conditions => "memberships.admin_role = #{true}"
  has_many :inbound_sms 
  has_many :outbound_sms
  
  class << self
    
    def exists?(name)
      find_by_title(name)
    end
    
    def create_group(name)
      group = Group.new(:title=>name, :company=>Thread.current[:current_company])
      group.save
      group
    end
    
    def create_group_for_user(admin, name, members)
      group = Group.new(:title=>name, :company=>Thread.current[:current_company])
      group.mods.build(admin)
      group.save
      group.add_members(members)
      group
    end
    
    def create_if_not_exists(name)
      group =  exists?(name)
      if group.nil?
        group = create_group(name)
      end
      group
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
    self.membership(user).destroy if user.is_member_of?(self)
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
    self.members.include?(user)
  end
  
  def has_admin?(user)
    self.mods.include?(user)
  end
  
  def add_members(users)
    users.each do |user|
      self.add_member(user)
    end
  end
  
  def add_member(user)
    membership = Membership.new(:group=>self, :user=>user)
    membership.save
  end
  
  def send_message(message, from, members=nil)
    outbounds_sms = []
    if members.nil?
      members = self.active_members
    end
    members.each do |member|
      outbound_sms = OutboundSms.new(:from=>from.mobile_no, :to=>member.mobile_no, :message=>message, :group=>self)
      outbounds_sms << outbound_sms
    end
    OutboundSms.queue_bulk(outbounds_sms)
  end  
 
  def get_list(user)
    self.has_member?(user) ? self.members.collect{|user| user.mobile_no}.join(',').to_s : false 
  end
end
