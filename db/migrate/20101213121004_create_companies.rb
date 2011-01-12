class CreateCompanies < ActiveRecord::Migration
  def self.up
    create_table :companies do |t|      
      t.string :name, :null => false
      t.string :username, :null => false
      t.string :password, :null => false
      t.string :address, :null => false
      t.string :authtoken, :null => false      
      t.timestamps
    end
  end

  def self.down
    drop_table :companies
  end
end
