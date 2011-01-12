class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def current_company
    Thread.current[:current_company] = Company.find(1)
  end
  
end
