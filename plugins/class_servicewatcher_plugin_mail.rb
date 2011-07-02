class ServiceWatcherPluginMail
	def self.paras
		return [
			{
				"title" => _("Host"),
				"name" => "txthost"
			},
			{
				"title" => _("Port"),
				"name" => "txtport"
			},
			{
				"title" => _("Type"),
				"opts" => [_("POP"), _("IMAP"), _("SMTP")],
				"name" => "seltype"
			},
			{
				"title" => _("SSL"),
				"name" => "chessl"
			},
			{
				"title" => _("Username"),
				"name" => "txtuser"
			},
			{
				"type" => "password",
				"title" => _("Password"),
				"name" => "txtpass"
			}
		]
	end
	
	def self.check(paras)
		if paras["chessl"] == "1"
			sslval = true
		else
			sslval = false
		end
		
		if paras["seltype"] == "IMAP"
			conn = Net::IMAP.new(paras["txthost"], paras["txtport"].to_i, sslval)
			conn.login(paras["txtuser"], paras["txtpass"])
		elsif paras["seltype"] == "POP"
			conn = Net::POP.new(paras["txthost"], paras["txtport"].to_i, sslval)
			conn.start(paras["txtuser"], paras["txtpass"])
		elsif paras["seltype"] == "SMTP"
			conn = Net::SMTP.new(paras["txthost"], paras["txtport"].to_i)
			
			if (sslval)
				conn.enable_ssl
			end
			
			conn.start(paras["txthost"], paras["txtuser"], paras["txtpass"]) do |smtp|
				#nothing here - but it is needed to raise error if failing.
			end
		end
	end
end