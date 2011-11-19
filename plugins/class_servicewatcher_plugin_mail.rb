class Service_watcher::Plugin::Mail < Service_watcher::Plugin
	def self.paras
		return [{
      "title" => _("Host"),
      "name" => "txthost"
    },{
      "title" => _("Port"),
      "name" => "txtport"
    },{
      "title" => _("Type"),
      "opts" => [_("POP"), _("IMAP"), _("SMTP")],
      "name" => "seltype"
    },{
      "title" => _("SSL"),
      "name" => "chessl"
    },{
      "title" => _("Username"),
      "name" => "txtuser"
    },{
      "type" => "password",
      "title" => _("Password"),
      "name" => "txtpass"
    }]
	end
	
	def self.check(paras)
		if paras["chessl"] == "1" or paras["chessl"] == "on"
			sslval = true
		else
			sslval = false
		end
		
		if paras["seltype"] == "IMAP" or paras["seltype"] == "1"
      require "net/imap"
			conn = Net::IMAP.new(paras["txthost"], paras["txtport"].to_i, sslval)
			conn.login(paras["txtuser"], paras["txtpass"]) if paras["txtuser"].to_s.length > 0 and paras["txtpass"].to_s.length > 0
		elsif paras["seltype"] == "POP" or paras["seltype"] == "0"
      require "net/pop"
			conn = Net::POP.new(paras["txthost"], paras["txtport"].to_i, sslval)
			conn.start(paras["txtuser"], paras["txtpass"]) if paras["txtuser"].to_s.length > 0 and paras["txtpass"].to_s.length > 0
		elsif paras["seltype"] == "SMTP" or paras["seltype"] == "2"
      require "net/smtp"
			conn = Net::SMTP.new(paras["txthost"], paras["txtport"].to_i)
      conn.enable_ssl if sslval
			
			conn.start(paras["txthost"], paras["txtuser"], paras["txtpass"]) do |smtp|
				#nothing here - but it is needed to raise error if failing.
			end
		else
      raise sprintf(_("Unknown type: '%s'."), paras["seltype"])
    end
	end
end