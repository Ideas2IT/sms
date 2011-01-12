class SmsController < ApplicationController
  
  def incoming_message
    InboundSms.parse_incoming_sms(params[:from], params[:message])
  end
  
end
