class User < ActiveRecord::Base
  include_simple_groups
  belongs_to :company
  has_many :groups, :through => :memberships, :conditions => 'accepted_at IS NOT NULL'
  named_scope :admin, :conditions => ["admin_role = ?", true]
  
  #named_scope :system_user, :conditions => ["id = ?", 1]
  
 class << self
   
   def system_user
     find(1)
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
     users
   end
   
   def form_user(mobile_no)
     user = User.find_by_mobile_no(mobile_no, :conditions => ['company_id = ?', Thread.current[:current_company].id])
     if user.nil?
       user = User.new(:mobile_no => mobile_no, :company=>Thread.current[:current_company])
       if user.save
         return user
       end
     else
       return user
     end     
   end
   
 end
 
 def is_member_of?(group)
    self.groups.include?(group)
 end
  
end
