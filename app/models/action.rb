class Action < ActiveRecord::Base
  has_many :inbound_sms
end
