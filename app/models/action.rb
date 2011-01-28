class Action < ActiveRecord::Base
  has_many :inbound_sms
  
  class << self
    
    def get_keywords
      action = Action.find(:all,:select=>"keyword")
      keywords = action.collect{|action| action.keyword}.join(',').to_s
      keywords
    end
    
  end
      
end
