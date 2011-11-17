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
		}]
	end
	
	def self.check(paras)
    raise "No arguments given." if paras.length <= 0
		paras["txttimeout"] = 7 if paras["txttimeout"].to_s.length <= 0
		
		require "net/http"
		require "net/https"
		
		http = Net::HTTP.new(paras["txthost"], paras["txtport"])
		http.read_timeout = paras["txttimeout"].to_i
		
		if paras["chessl"] == "1" or paras["chessl"] == "on"
			require "net/https"
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		end
		
		resp, data = http.get2("/#{paras["txtaddr"]}")
	end
end