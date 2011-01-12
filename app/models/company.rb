class Company < ActiveRecord::Base
  has_many :groups
  has_many :users
  has_one :admin, :through => :users, :conditions => ['admin_role = ?', true]
  
  def admin_user
    User.find_by_admin_role(true, :conditions => ["company_id = '?'", self.id])
  end
  
end
