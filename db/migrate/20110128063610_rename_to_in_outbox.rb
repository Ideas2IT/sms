class RenameToInOutbox < ActiveRecord::Migration
  def self.up
    query = "ALTER TABLE `outbound_sms` CHANGE `to` `to_no` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL;"
    connection.execute(query)
    query = "ALTER TABLE `outbound_sms` CHANGE `from` `from_no` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL;"
    connection.execute(query)
  end

  def self.down
  end
end
