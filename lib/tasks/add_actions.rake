# Provide tasks to load data specific to delhi
require 'active_record'
require 'active_record/fixtures'
require 'logger'


namespace :db do
  namespace :add_actions do
    desc "load actions"
    task :load => :environment do |t|
      load_actions
    end
  end
end

def load_actions
  logger = Logger.new STDOUT
  name_arr=['ADD_USER_TO_GROUP_FROM_ADMIN','LIST_ALL_USERS','SEND_MESSAGE_TO_GROUP','MUTE','REJOIN','UNSUBSCRIBE','REMOVE']
  description_arr=['Creating a new Group','Listing Users of a Group ','Messages sent by users of a Group','Temporary Disconnect','Joining after temporary Disconnection','Removing a User from a Group','Removing a group from Subscription']
  keywords_arr=['add','list','sendmsg','mute','rejoin','unsub','rmv']
  keywords_arr.each_with_index do |keyword,i|
  action = Action.find_by_keyword(keyword)
    if action.nil?
      action = Action.new(:name=>name_arr[i],:description=>description_arr[i],:keyword=>keyword)
      action.save
    else
      action.update_attributes(:name=>name_arr[i],:description=>description_arr[i],:keyword=>keyword)
    end
    logger.info "action added for #{keyword}" 
  end
end
