class Service_watcher::Service_reporterlink < Knj::Datarow
	def self.list(d)
		sql = "SELECT * FROM services_reporterlinks WHERE 1=1"
		
		ret = list_helper(d)
		d.args.each do |key, val|
        raise sprintf(_("Invalid key: %s."), key)
		end
		
		sql += ret[:sql_where]
		sql += ret[:sql_order]
		sql += ret[:sql_limit]
		
		return d.ob.list_bysql(:Service_reporterlink, sql)
	end
	
	def self.add(d)
		service = d.ob.get(:Service, data[:service_id])
		reporter = d.ob.get(:Reporter, data[:reporter_id])
		
		link = d.ob.list(:Service_reporterlink, {"service" => service, "reporter" => reporter})
		if link.length > 0
			raise Errors::Notice, _("Such a reporter is already added for that service.")
		end
	end
	
	def reporter
		return ob.get(:Reporter, self["reporter_id"])
	end
	
	def service
		return ob.get(:Service, self["service_id"])
	end
	
	def title
		return self.reporter.title
	end
end