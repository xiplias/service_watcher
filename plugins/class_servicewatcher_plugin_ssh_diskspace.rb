class Service_watcher::Plugin::Ssh_diskspace < Service_watcher::Plugin
	def self.paras
		return [{
			"title" => _("Hostname"),
			"name" => "txthost"
		},{
			"title" => _("Port"),
			"name" => "txtport",
			"default" => "22"
		},{
			"title" => _("Username"),
			"name" => "txtuser"
		},{
			"type" => "password",
			"title" => _("Password"),
			"name" => "txtpasswd"
		},{
			"title" => _("Path"),
			"name" => "txtpath"
		},{
			"title" => _("Warning percent"),
			"name" => "txtwarnperc"
		}]
	end
	
	def self.check(paras)
		sshrobot = Knj::SSHRobot.new(
			"host" => paras["txthost"],
			"port" => paras["txtport"].to_i,
			"user" => paras["txtuser"],
			"passwd" => paras["txtpasswd"]
		)
		
		if !Php.is_numeric(paras["txtwarnperc"])
			raise "Warning percent is not numeric - please enter it correctly as number only."
		end
		
		warnperc = paras["txtwarnperc"].to_i
		output = sshrobot.exec("df -m -P " + Knj::Strings::UnixSafe(paras["txtpath"]))
		
		match = output.match(/([0-9]+)%/)
		
		if !match or !match[1] or !Php.is_numeric(match[1])
			raise _("Error in result from the server.")
		end
		
		if match[1].to_i > warnperc
			raise "Diskspace percent is " + match[1] + " - warning percent is " + warnperc.to_s + "."
		end
	end
end