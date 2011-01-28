class AddActualNameToGroup < ActiveRecord::Migration
  def self.up
    add_column :groups, :actual_name, :string, :null=>false
  end

  def self.down
    remove_column :groups, :actual_name
  end
end
