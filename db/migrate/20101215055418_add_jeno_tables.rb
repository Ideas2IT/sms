class AddJenoTables < ActiveRecord::Migration
  def self.up
    query="
CREATE TABLE IF NOT EXISTS `jenocalls` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `call_date` datetime NOT NULL,
  `gateway_id` varchar(64) NOT NULL,
  `caller_id` varchar(30) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;"
  results = connection.execute(query)
  
  query="
CREATE TABLE IF NOT EXISTS `jenoinbox` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `sender` varchar(13) NOT NULL,
  `type` varchar(1) NOT NULL,
  `encoding` varchar(1) NOT NULL,
  `message_date` datetime NOT NULL,
  `message` varchar(1500) DEFAULT NULL,
  `gateway_id` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;"
  results = connection.execute(query)
  
  query="CREATE TABLE IF NOT EXISTS `jenooutbox` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `mobilenumber` varchar(13) NOT NULL,
  `message` varchar(2000) NOT NULL,
  `date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `flash_sms` int(1) NOT NULL DEFAULT '0',
  `priority` int(2) NOT NULL DEFAULT '0',
  `encoding` varchar(1) NOT NULL DEFAULT '7',
  `status` varchar(1) NOT NULL DEFAULT 'U',
  `errors` int(2) NOT NULL DEFAULT '0',
  `status_report` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;"
  results = connection.execute(query)
  
  query="CREATE TABLE IF NOT EXISTS `jenosentsms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `mobilenumber` varchar(13) NOT NULL,
  `message` varchar(2000) DEFAULT NULL,
  `sent_date` datetime DEFAULT NULL,
  `ref_no` varchar(64) DEFAULT NULL,
  `status` varchar(1) DEFAULT NULL,
  `gateway_id` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;"
  results = connection.execute(query)
  end

  def self.down
  end
end
