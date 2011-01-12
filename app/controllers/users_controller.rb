class UsersController < ApplicationController
  before_filter :current_company
  def join_group
    
  end
  
  def show_contact_admin
    
  end
  
  def sms_admin
    if params[:mobile_no].nil? or params[:mobile_no] == "" or params[:message].nil? or params[:message] == ""
    else
      OutboundSms.contact_admin(params[:mobile_no], params[:message])
    end
    render :text => "Sms success"
  end
  
  def sms_user_from_admin   
    
  end
  
end
