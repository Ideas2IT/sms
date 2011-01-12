class CreateActions < ActiveRecord::Migration
  def self.up
    create_table :actions do |t|
      t.string :name, :null=>false
      t.string :description
      t.string :keyword, :null=>false
      t.timestamps
    end
  end

  def self.down
    drop_table :actions
  end
end
