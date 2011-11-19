class Service_watcher::Plugin::Ftp < Service_watcher::Plugin
	def self.paras
		return [{
			"title" => _("Port"),
			"name" => "txtport",
			"default" => 21
		},{
			"title" => _("Hostname"),
			"name" => "txthost"
		},{
			"title" => _("Username"),
			"name" => "txtusername"
		},{
			"title" => _("Password"),
			"name" => "txtpassword",
			"type" => "password"
		}]
	end
	
	def self.check(paras)
    raise "No arguments given." if paras.length <= 0
		paras["txttimeout"] = 7 if paras["txttimeout"].to_s.length <= 0
		
		require "net/ftp"
		
		begin
      ftp = Net::FTP.new
      ftp.connect(paras["txthost"], paras["txtport"].to_i)
      ftp.login(paras["txtusername"], paras["txtpassword"])
      ftp.list
    rescue Errno::ECONNREFUSED
      raise sprintf(_("Connection refused when connecting to '%1$s:%2$s'."), paras["txthost"], paras["txtport"])
    end
	end
end