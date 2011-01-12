class Action < ActiveRecord::Base
  has_many :inbound_sms, :outbound_sms
end
