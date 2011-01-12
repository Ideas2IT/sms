# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110112093446) do


  create_table "actions", :force => true do |t|
    t.string   "name",        :null => false
    t.string   "description"
    t.string   "keyword",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "companies", :force => true do |t|
    t.string   "name",       :null => false
    t.string   "username",   :null => false
    t.string   "password",   :null => false
    t.string   "address",    :null => false
    t.string   "authtoken",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups", :force => true do |t|
    t.string   "title"
    t.integer  "created_by"
    t.integer  "company_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "inbound_sms", :force => true do |t|
    t.string   "source",                                 :null => false
    t.string   "message"
    t.string   "token"
    t.string   "intended_to",      :default => "system", :null => false
    t.integer  "thread_source_id"
    t.integer  "action_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "jenocalls", :force => true do |t|
    t.datetime "call_date",                :null => false
    t.string   "gateway_id", :limit => 64, :null => false
    t.string   "caller_id",  :limit => 30, :null => false
  end

  create_table "jenoinbox", :force => true do |t|
    t.string   "sender",       :limit => 13,   :null => false
    t.string   "type",         :limit => 1,    :null => false
    t.string   "encoding",     :limit => 1,    :null => false
    t.datetime "message_date",                 :null => false
    t.string   "message",      :limit => 1500
    t.string   "gateway_id",   :limit => 64
  end

  create_table "jenooutbox", :force => true do |t|
    t.string    "mobilenumber",  :limit => 13,                    :null => false
    t.string    "message",       :limit => 2000,                  :null => false
    t.timestamp "date"
    t.integer   "flash_sms",                     :default => 0,   :null => false
    t.integer   "priority",                      :default => 0,   :null => false
    t.string    "encoding",      :limit => 1,    :default => "7", :null => false
    t.string    "status",        :limit => 1,    :default => "U", :null => false
    t.integer   "errors",                        :default => 0,   :null => false
    t.integer   "status_report",                 :default => 0,   :null => false
  end

  create_table "jenosentsms", :force => true do |t|
    t.string   "mobilenumber", :limit => 13,   :null => false
    t.string   "message",      :limit => 2000
    t.datetime "sent_date"
    t.string   "ref_no",       :limit => 64
    t.string   "status",       :limit => 1
    t.string   "gateway_id",   :limit => 64
  end

  create_table "memberships", :force => true do |t|
    t.integer  "user_id",                        :null => false
    t.integer  "group_id",                       :null => false
    t.datetime "accepted_at"
    t.boolean  "admin_role",  :default => false
    t.boolean  "muted",       :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "mute",        :default => false
  end

  create_table "outbound_sms", :force => true do |t|
    t.string   "from",              :default => "system", :null => false
    t.string   "to",                                      :null => false
    t.string   "message",                                 :null => false
    t.string   "token",                                   :null => false
    t.boolean  "gateway_delivered", :default => false
    t.integer  "thread_source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "mobile_no",                     :null => false
    t.integer  "company_id",                    :null => false
    t.boolean  "admin_role", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
