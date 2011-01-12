module UsersHelper
  
  def company_valid(token)
    Company.find_by_authtoken(token)
  end
  
end
