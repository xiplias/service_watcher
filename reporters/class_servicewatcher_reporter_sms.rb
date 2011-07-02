class ServiceWatcherReporterSms
	def self.paras
		return [
			{
				"title" => _("Type"),
				"name" => "seltype",
				"opts" => ["BiBoB"]
			},
			{
				"title" => _("Username"),
				"name" => "txtuser"
			},
			{
				"title" => _("Password"),
				"name" => "txtpass",
				"type" => "password"
			},
			{
				"name" => "txtphonenumber",
				"title" => _("Phone number")
			}
		]
	end
	
	def initialize(paras)
		@paras = paras
	end
	
	def report_error(data)
		message = "ServiceWatcher error\n\n"
		message += "Group: " + data["service"].group.title + "\n"
		message += "Service: " + data["service"].title + "\n"
		message += "Type: " + data["error"].class.to_s + "\n"
		message += "Date: " + Datestamp.out + "\n"
		message += "Error:\n\n"
		message += data["error"].inspect.to_s
		
		sms = Knj::Sms.new(
			"type" => @paras["seltype"].downcase,
			"user" => @paras["txtuser"],
			"pass" => @paras["txtpass"]
		)
		sms.send_sms(@paras["txtphonenumber"], message)
	end
end