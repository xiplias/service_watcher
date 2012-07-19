class Service_watcher::Reporter::Email < Service_watcher::Reporter
	def self.paras
		return [{
      "type" => "text",
      "name" => "txtaddress",
      "title" => _("Email address")
    },{
      "type" => "text",
      "name" => "txtfromaddress",
      "title" => _("From email address")
    },{
      "type" => "text",
      "name" => "txtsubject",
      "title" => _("Subject")
    }]
	end
	
	def initialize(paras)
		@paras = paras
	end
	
	def report_error(error_hash)
		#print "Report error: " + error_hash["error"].inspect
		
		require "datet"
		require "knj/web"
		require "knj/php"
		require "knj/errors"
		
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
		html += "<td>#{Datet.new.out.html}</td>"
		html += "</tr><tr>"
		html += "<td colspan=\"2\"><b>#{_("Error")}</b></td>"
		html += "</tr><tr>"
		html += "<td colspan=\"2\" style=\"margin-left: 9px;\">#{Knj::Php.nl2br(Knj::Errors.error_str(error_hash["error"]).to_s.html)}</td>"
		html += "</tr></table>"
		
		_kas.mail(
      :to => details["txtaddress"],
      :from => details["txtfromaddress"],
      :subject => Service_watcher.parse_subject(
        "error" => error_hash["error"],
        "subject" => details["txtsubject"]
      ),
      :html => html
		)
	end
end