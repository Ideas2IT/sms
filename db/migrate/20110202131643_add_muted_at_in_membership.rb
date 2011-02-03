class AddMutedAtInMembership < ActiveRecord::Migration
  def self.up
     add_column :memberships,:muted_at,:datetime
  end

  def self.down
    remove_column :memberships,:muted_at
  end
end
