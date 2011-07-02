class Service_watcher::Service < Knj::Datarow
	def self.list(d)
		sql = "SELECT * FROM services WHERE 1=1"
		
		ret = list_helper(d)
		d.args.each do |key, val|
        raise sprintf(_("Invalid key: %s."), key)
		end
		
		sql += ret[:sql_where]
		sql += ret[:sql_order]
		sql += ret[:sql_limit]
		
		return d.ob.list_bysql(:Service, sql)
	end
	
	def delete
		self.del_details
	end
	
	def del_details
		db.delete("services_options", {"service_id" => self["id"]})
	end
	
	def add_detail(name, data)
		db.insert("services_options", {
			"service_id" => self["id"],
			"opt_name" => name,
			"opt_value" => data
		})
	end
	
	def details
		data = {}
		q_details = db.select(:services_options, {"service_id" => self["id"]})
		while d_details = q_details.fetch
			data[d_details["opt_name"]] = d_details["opt_value"]
		end
		
		return data
	end
	
	def reporters
		return ob.list("Service_reporterlink", {"service" => self})
	end
	
	def reporters_merged
		reporters = []
		self.reporters.each do |link|
			reporters << link.reporter
		end
		
		group.reporters.each do |link|
			if !reporters.index(link.reporter)
				reporters << link.reporter
			end
		end
		
		return reporters
	end
	
	def group
		return ob.get(:Group, self[:group_id])
	end
end