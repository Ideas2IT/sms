class SmsController < ApplicationController
  
  def incoming_message
    mobile_no = params[:from]
    mobile_no = mobile_no[-10..-1]
    InboundSms.parse_incoming_sms(mobile_no, params[:message])
  end
  
end
