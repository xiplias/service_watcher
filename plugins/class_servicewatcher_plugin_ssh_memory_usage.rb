class Service_watcher::Plugin::Ssh_memory_usage < Service_watcher::Plugin
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
			"title" => _("Warning percent"),
			"name" => "txtwarnperc"
		}]
	end
	
	def self.check(paras)
    Knj.gem_require(:Tretry, "tretry")
    warn_perc = paras["txtwarnperc"].to_f
    
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
      
      output = sshrobot.exec("ps aux")
      sshrobot.close
    end
    
    Knj::Unix_proc.list("psaux_res" => output, "yield_data" => true) do |data|
      if data["ram_last"].to_f >= warn_perc
        raise "The process with PID '#{data["pid"]}' from '#{data["user"]}' had '#{data["ram_last"].to_f.round(2)}%' memory usage: '#{data["app"]}'."
      end
    end
	end
end