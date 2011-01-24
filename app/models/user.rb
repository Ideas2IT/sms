class User < ActiveRecord::Base
  include_simple_groups
  belongs_to :company
  has_many :groups, :through => :memberships, :conditions => 'accepted_at IS NOT NULL'
  validates_numericality_of :mobile_no, :message => "Phone No. must be numerals"
      validates_length_of :mobile_no, :is=>10, :message => "is invalid"
  #named_scope :admin, :conditions => ["admin_role = ?", true]
  
  #named_scope :system_user, :conditions => ["id = ?", 1]
  
 class << self
   
   def system_user
     find_by_mobile_no(SYSTEM_MOBILE_NO)
   end
   def exists?(mobile)
     find_by_mobile_no(mobile)
   end
   
   def get_if_admin(mobile_no)
     User.find_by_admin_role(true, :conditions => ["mobile_no = ?", mobile_no])
   end
   
   def form_users(mobile_nos)
     users = []
     mobile_nos.each do |mobile_no|
       users << form_user(mobile_no)
     end
     puts "users....#{users.inspect}"
     users
   end
   
   def form_user(mobile_no)
     user = User.find_by_mobile_no(mobile_no, :conditions => ['company_id = ?', Thread.current[:current_company].id])
     if user.nil?
       user = User.new(:mobile_no => mobile_no, :company=>Thread.current[:current_company])
       begin
         user.save!
         #return user
       rescue Exception => e
         puts "in exception........#{e.message}"
         err =  mobile_no
       end
     else
       #return user
     end
     return {:user=>user, :err=>err}
   end
   
   def slice_invalid_users(users)
     members = []
     invalid_members = []
     users.each do |user|
       if user[:err].nil?
         members<<user[:user]
       else
         invalid_members<<user[:err]
       end
     end
     return members, invalid_members
   end
   
 end
 
 def is_member_of?(group)
    self.groups.include?(group)
 end
 
 def intimate_invalid_members(invalid_members)
   invalid_numbers = invalid_members.join(",").to_s
   message = "The numbers you provided #{invalid_numbers} are invalid"
   outbound_sms = OutboundSms.new(:from=>User.system_user.mobile_no, :to=>self.mobile_no, :message=>message)
   outbound_sms.queue_sms
 end
 
 def intimate_existing_members(existing_members, group_name)
   existing_numbers = existing_members.collect{|user| user.mobile_no}.join(",").to_s
   message = "The numbers you provided #{existing_numbers} are already a member of the group #{group_name}"
   outbound_sms = OutboundSms.new(:from=>User.system_user.mobile_no, :to=>self.mobile_no, :message=>message)
   outbound_sms.queue_sms
 end
  
end
