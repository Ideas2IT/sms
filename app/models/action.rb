class Action < ActiveRecord::Base
  has_many :inbound_sms
  
  class << self
    
    def get_keywords
      #action = Action.find(:all,:select=>"keyword")
      #keywords = action.collect{|action| action.keyword}.join(',').to_s
     keywordformat_help = "Sms: Add+(space)+groupname+(space)+(phno1,phno2,phno...)to(Phone number),"+
       "list+(space)+(groupname)to(Phone number),"+"unsub+(space)+(groupname)to(Phone number),"+
       "rmv+(space)+(phno)to(Phone number),"+"mute+(space)+(groupname)to(Phone number),"+
       "rejoin+(space)+(groupname)to(Phone number),"+"invite+(space)+(groupname)+(space)+(phno)to(Phone number),"+
       "msg+(space)+groupname+(space)+(your message)to(Phone number)+ to send msg to all the members,"
      keywordformat_help
    end
    
  end
      
end
