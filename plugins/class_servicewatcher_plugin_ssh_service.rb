class Service_watcher::Plugin::Ssh_service < Service_watcher::Plugin
	def self.paras
		return [
			{
				"title" => _("Port"),
				"name" => "txtport",
				"default" => "22"
			},{
				"title" => _("Hostname"),
				"name" => "txthost"
			},{
				"title" => _("Username"),
				"name" => "txtuser"
			},{
				"type" => "password",
				"title" => _("Password"),
				"name" => "txtpasswd"
			},{
        "title" => _("Service name"),
        "name" => "txtservicename"
			},{
        "title" => _("Sudo password"),
        "name" => "txtsudopasswd",
        "type" => "password"
      }
		]
	end
	
	def self.check(paras)
    sshrobot = Knj::SSHRobot.new(
      "host" => paras["txthost"],
      "port" => paras["txtport"],
      "user" => paras["txtuser"],
      "passwd" => paras["txtpasswd"]
    )
    
    cmd = "service #{Knj::Strings.unixsafe(paras["txtservicename"])} status"
    
    if paras["txtsudopasswd"].to_s.strip.length > 0
      res = sshrobot.sudo_exec(paras["txtsudopasswd"], cmd)
    else
      res = sshrobot.exec(cmd)
    end
    
    res = res.to_s.strip
    result = false
    
    if res =~ /is\s+running\s*$/ or res =~ /is\s+running\s*\(pid\s+(\d+)\)\s*(\.|)\s*$/
      result = true
    end
    
    if !result
      raise sprintf(_("Looks like the service %1$s is not running: '%2$s'."), paras["txtservicename"], res.to_s.strip)
    end
    
    sshrobot.close
	end
end