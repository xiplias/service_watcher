class ServiceWatcherPluginMysql
	def self.paras
		return [
			{
				"title" => _("Hostname"),
				"name" => "txthost"
			},
			{
				"title" => _("Port"),
				"name" => "txtport",
				"default" => "3306"
			},
			{
				"title" => _("Username"),
				"name" => "txtuser"
			},
			{
				"type" => "password",
				"title" => _("Password"),
				"name" => "txtpasswd"
			},
			{
				"title" => _("Database"),
				"name" => "txtdb",
				"default" => "mysql"
			}
		]
	end
	
	def self.check(paras)
		begin
			conn = Mysql.real_connect(paras["txthost"], paras["txtuser"], paras["txtpasswd"], paras["txtdb"], paras["txtport"].to_i)
		rescue => e
			raise "MySQL connection failed for #{paras["txtuser"]}@#{paras["txthost"]}:#{paras["txtdb"]}! - " + e.inspect
		end
	end
end