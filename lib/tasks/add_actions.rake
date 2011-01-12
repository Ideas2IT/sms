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
  name_arr=['ADD','LIST']
  description_arr=['Adding Elements to Group','Listing Group Elements']
  keywords_arr=['add','list']
  keywords_arr.each_with_index do |keyword,i|
    if Action.find_by_keyword(keyword).nil?
      action = Action.new(:name=>name_arr[i],:description=>description_arr[i],:keyword=>keyword)
      action.save
    end
    logger.info "action added for #{keyword}" 
  end
end
