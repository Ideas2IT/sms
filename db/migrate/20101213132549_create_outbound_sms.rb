class CreateOutboundSms < ActiveRecord::Migration
  def self.up
    create_table :outbound_sms do |t|      
      t.string :from, :null => false, :length => 13, :default => "system"
      t.string :to, :null => false, :length => 13
      t.string :message, :null => false
      t.string :token
      t.boolean :gateway_delivered, :default => false
      t.integer :thread_source_id
      t.integer :group_id
      t.timestamps
    end
  end

  def self.down
    drop_table :outbound_sms
  end
end
