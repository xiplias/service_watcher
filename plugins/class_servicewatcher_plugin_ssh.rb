class ServiceWatcherPluginSsh
	def self.paras
		return [
			{
				"title" => _("Port"),
				"name" => "txtport",
				"default" => "22"
			},
			{
				"title" => _("Hostname"),
				"name" => "txthost"
			},
			{
				"title" => _("Username"),
				"name" => "txtuser"
			},
			{
				"type" => "password",
				"title" => _("Password"),
				"name" => "txtpasswd"
			}
		]
	end
	
	def self.check(paras)
		begin
			sshrobot = Knj::SSHRobot.new(
				"host" => paras["txthost"],
				"port" => paras["txtport"],
				"user" => paras["txtuser"],
				"passwd" => paras["txtpasswd"]
			).session
		rescue => e
			raise "SSH connection failed for #{paras["txtuser"]}@#{paras["txthost"]}:#{paras["txtport"]}!"
		end
	end
end