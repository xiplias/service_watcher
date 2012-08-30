class Service_watcher::Plugin::Http < Service_watcher::Plugin
	def self.paras
		return [{
			"title" => _("Port"),
			"name" => "txtport",
			"default" => "80"
		},{
			"title" => _("Hostname"),
			"name" => "txthost"
		},{
			"title" => _("Get address"),
			"name" => "txtaddr"
		},{
			"title" => _("SSL"),
			"name" => "chessl"
		},{
			"title" => _("Timeout"),
			"name" => "txttimeout",
			"default" => 7
    },{
      "title" => _("HTML regex match"),
      "name" => "txthtmlregexmatch"
		}]
	end
	
	def self.check(paras)
    raise "No arguments given." if paras.length <= 0
		paras["txttimeout"] = 7 if paras["txttimeout"].to_s.length <= 0
		
		require "net/http"
		require "net/https"
		
		Tretry.try(:tries => 3, :wait => 2, :errors => [SocketError, Timeout::Error]) do
      http = Net::HTTP.new(paras["txthost"], paras["txtport"])
      http.read_timeout = paras["txttimeout"].to_i
      
      if paras["chessl"] == "1" or paras["chessl"] == "on"
        require "net/https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      
      resp, data = http.get2("/#{paras["txtaddr"]}")
      
      if paras["txthtmlregexmatch"].to_s.length > 0
        regex = Knj::Strings.regex(paras["txthtmlregexmatch"])
        raise sprintf(_("Could not match the following regex: '%1$s'."), paras["txthtmlregexmatch"]) if !regex.match(data)
      end
		end
	end
end