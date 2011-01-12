class AddMuteToMemberships < ActiveRecord::Migration
  def self.up
    add_column :memberships,:mute,:boolean,:default=>false
  end

  def self.down
    remove_column :memberships,:mute
  end
end
