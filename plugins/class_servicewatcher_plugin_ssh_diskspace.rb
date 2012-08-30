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
    output = nil
    Tretry.try(:tries => 3, :timeout => 15, :wait => 2, :errors => [Errno::ETIMEDOUT, Errno::EHOSTUNREACH]) do
      sshrobot = Knj::SSHRobot.new(
        "host" => paras["txthost"],
        "port" => paras["txtport"].to_i,
        "user" => paras["txtuser"],
        "passwd" => paras["txtpasswd"]
      )
      
      if !(Float(paras["txtwarnperc"]) rescue false)
        raise _("Warning percent is not numeric - please enter it correctly as number only.")
      end
      
      output = sshrobot.exec("df -m -P #{Knj::Strings.unixsafe(paras["txtpath"])}")
      
      if output.index("invalid option -- P") != nil
        output = sshrobot.exec("df -m #{Knj::Strings.unixsafe(paras["txtpath"])}")
      end
      
      sshrobot.close
    end
		
		match = output.match(/([0-9]+)%/)
		
		if !match or !match[1] or !(Float(match[1]) rescue false)
			raise _("Error in result from the server.") + "\n\nMatch:\n#{Php4r.print_r(match, true)}\n\nResult:\n#{output}"
		end
		
		warnperc = paras["txtwarnperc"].to_i
		if match[1].to_i > warnperc
			raise "Diskspace percent is " + match[1] + " - warning percent is " + warnperc.to_s + "."
		end
	end
end