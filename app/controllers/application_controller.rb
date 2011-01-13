class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :current_company
  def current_company
    Thread.current[:current_company] = Company.find(1)
  end
  
end
