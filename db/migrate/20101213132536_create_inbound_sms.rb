class CreateInboundSms < ActiveRecord::Migration
  def self.up
    create_table :inbound_sms do |t|
      t.string :source, :null => false
      t.string :message
      t.string :token
      t.string :intended_to, :null => false, :default => "system"
      t.integer :thread_source_id
      t.integer :action_id
      t.integer :user_id
      t.integer :group_id
      t.timestamps
    end
  end

  def self.down
    drop_table :inbound_sms
  end
end
