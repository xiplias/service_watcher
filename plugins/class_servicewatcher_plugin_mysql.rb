class Service_watcher::Plugin::Mysql < Service_watcher::Plugin
	def self.paras
		return [{
      "title" => _("Hostname"),
      "name" => "txthost"
    },{
      "title" => _("Port"),
      "name" => "txtport",
      "default" => "3306"
    },{
      "title" => _("Username"),
      "name" => "txtuser"
    },{
      "type" => "password",
      "title" => _("Password"),
      "name" => "txtpasswd"
    },{
      "title" => _("Database"),
      "name" => "txtdb",
      "default" => "mysql"
    }]
	end
	
	def self.check(paras)
    require "mysql2"
    
		begin
      args = {
        :host => paras["txthost"],
        :username => paras["txtuser"],
        :password => paras["txtpasswd"],
        :port => paras["txtport"].to_i,
        :symbolize_keys => true
      }
      
      conn = Mysql2::Client.new(args)
      conn.close
		rescue => e
			raise "MySQL connection failed for #{paras["txtuser"]}@#{paras["txthost"]}:#{paras["txtdb"]}! - " + e.inspect
		end
	end
end