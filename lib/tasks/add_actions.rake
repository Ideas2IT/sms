# Provide tasks to load data specific to delhi
require 'active_record'
require 'active_record/fixtures'
require 'logger'


namespace :db do
  namespace :load_defaults do
    desc "load "
    task :load => :environment do |t|
      load_actions
      add_system_user
    end
    desc "load actions"
    task :load_actions => :environment do |t|
      load_actions
    end
    desc "add system user"
    task :load_system_users => :environment do |t|
      add_system_user
    end
  end
end

def load_actions
  logger = Logger.new STDOUT
  name_arr=['ADD_USER_TO_GROUP_FROM_ADMIN','LIST_ALL_USERS','SEND_MESSAGE_TO_GROUP','MUTE','REJOIN','INVITE_USERS_TO_GROUP','UNSUBSCRIBE','REMOVE','HELP','GROUPS','NICK','INACTIVE','HISTORY']
  description_arr=['Creating a new Group','Listing Users of a Group ','Messages sent by users of a Group','Temporary Disconnection','Joining after temporary Disconnection','Inviting Users to join in to a Group','Removing a User from a Group','Removing a group from Subscription','suggests user with the list of available keyword','lists the groups which the user is a member of','nick name of the user','lists the muted members of the group','messages that a muted user did not receive are sent' ]
  keywords_arr=['add','list','msg','mute','rejoin','invite','unsub','rmv','help','groups','nick','inactive','history']
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

def add_system_user
  logger = Logger.new STDOUT
  user = User.find_by_mobile_no(SYSTEM_MOBILE_NO)
  if user.nil?
    user = User.new(:mobile_no=> SYSTEM_MOBILE_NO,:company_id=>1)
    user.save
  end
  logger.info "action added for system user #{SYSTEM_MOBILE_NO}"
end
