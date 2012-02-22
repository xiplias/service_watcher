class Service_watcher::Plugin::Ssh_ftp < Service_watcher::Plugin
	def self.paras
		return [{
			"title" => _("SSH hostname"),
			"name" => "txtsshhost"
		},{
			"title" => _("SSH port"),
			"name" => "txtsshport",
			"default" => "22"
		},{
			"title" => _("SSH username"),
			"name" => "txtsshuser"
		},{
			"type" => "password",
			"title" => _("SSH password"),
			"name" => "txtsshpasswd"
		},{
			"title" => _("FTP hostname"),
			"name" => "txtftphost"
		},{
			"title" => _("FTP port"),
			"name" => "txtftpport"
		},{
			"title" => _("FTP username"),
			"name" => "txtftpuser"
		},{
			"title" => _("FTP password"),
			"name" => "txtftppasswd",
			"type" => "password"
		}]
	end
	
	def self.check(paras)
    require "knj/strings"
    
		sshrobot = Knj::SSHRobot.new(
			"host" => paras["txtsshhost"],
			"port" => paras["txtsshport"].to_i,
			"user" => paras["txtsshuser"],
			"passwd" => paras["txtsshpasswd"]
		)
		sshrobot.session
		
		if !sshrobot.fileExists("/usr/bin/lftp")
			raise "lftp is not installed on server."
		end
		
		output = sshrobot.exec("/usr/bin/lftp #{Knj::Strings.unixsafe(paras["txtftphost"])} -p #{Knj::Strings.unixsafe(paras["txtftpport"])} -u #{Knj::Strings.unixsafe(paras["txtftpuser"])},#{Knj::Strings.unixsafe(paras["txtftppasswd"])} -d -e \"ls;quit\"")
		sshrobot.close
		
		if !output.index("<--- 226 Transfer")
			raise output
		end
	end
end