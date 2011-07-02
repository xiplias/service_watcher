class ServiceWatcherReporterEmail
	def self.paras
		return [
			{
				"type" => "text",
				"name" => "txtsmtphost",
				"title" => _("SMTP host"),
				"default" => "localhost"
			},
			{
				"type" => "text",
				"name" => "txtsmtpport",
				"title" => _("SMTP port"),
				"default" => "25"
			},
			{
				"type" => "text",
				"name" => "txtsmtpuser",
				"title" => _("SMTP user")
			},
			{
				"type" => "password",
				"name" => "txtsmtppasswd",
				"title" => _("SMTP password")
			},
			{
				"type" => "text",
				"name" => "txtsmtpdomain",
				"title" => _("SMTP Domain")
			},
			{
				"type" => "text",
				"name" => "txtaddress",
				"title" => _("Email address")
			},
			{
				"type" => "text",
				"name" => "txtfromaddress",
				"title" => _("From email address")
			},
			{
				"type" => "text",
				"name" => "txtsubject",
				"title" => _("Subject")
			},
			{
				"type" => "check",
				"name" => "chessl",
				"title" => "SSL"
			}
		]
	end
	
	def initialize(paras)
		@paras = paras
	end
	
	def report_error(error_hash)
		#print "Report error: " + error_hash["error"].inspect
		
		require "knj/web"
		details = error_hash["reporter"].details
		
		html = "<h1>" + _("An error occurred") + "</h1><br />\n"
		html += "<table><tr>"
		html += "<td><b>#{_("Group")}</b></td>"
		html += "<td>#{error_hash["service"].group.title.html}</td>"
		html += "</tr><tr>"
		html += "<td><b>#{_("Service")}</b></td>"
		html += "<td>#{error_hash["service"].title.html}</td>"
		html += "</tr><tr>"
		html += "<td><b>#{_("Error")}</b></td>"
		html += "<td>#{error_hash["error"].class.to_s.html}</td>"
		html += "</tr><tr>"
		html += "<td><b>#{_("Date")}</b></td>"
		html += "<td>#{Datestamp.out(Time.now).html}</td>"
		html += "</tr><tr>"
		html += "<td colspan=\"2\"><b>#{_("Error")}</b></td>"
		html += "</tr><tr>"
		html += "<td colspan=\"2\" style=\"margin-left: 9px;\">" + Php.nl2br(error_hash["error"].inspect.to_s.html) + "</td>"
		html += "</tr></table>"
		html += "<td colspan=\"2\"><b>#{_("Traceback")}</b></td>"
		html += "<td colspan=\"2\" style=\"margin-left: 9px;\"></td>"
		
		if details["chessl"] == "1"
			ssl = true
		else
			ssl = false
		end
		
		mail = Knj::Mail.new(
			"from" => details["txtfromaddress"],
			"subject" => ServiceWatcher::parse_subject(
				"error" => error_hash["error"],
				"subject" => details["txtsubject"]
			),
			"to" => details["txtaddress"],
			"html" => html,
			"ssl" => ssl,
			"smtp_host" => details["txtsmtphost"],
			"smtp_port" => details["txtsmtpport"].to_i,
			"smtp_user" => details["txtsmtpuser"],
			"smtp_passwd" => details["txtsmtppasswd"],
			"smtp_domain" => details["txtsmtpdomain"]
		)
		mail.send
	end
end