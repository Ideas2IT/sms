class User < ActiveRecord::Base
  include_simple_groups
  belongs_to :company
  
  named_scope :admin, :conditions => ["admin_role = ?", true] 
  
 class << self
   
   def get_if_admin(mobile_no)
     User.find_by_admin_role(true, :conditions => ["mobile_no = ?", mobile_no])
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
  
end
