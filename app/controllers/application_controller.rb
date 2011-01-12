class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def current_company
    company = Company.find_by_authtoken(params[:id])
    unless company.nil?
      Thread.current[:current_company] = company
    end
  end
  
end
