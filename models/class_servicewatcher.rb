class ServiceWatcher
	def self.plugin_class(string)
		object_name = "ServiceWatcherPlugin" + Php.ucwords(string)
		return Kernel.const_get(object_name)
	end
	
	def self.check_and_report(paras)
		staticmethod = false
		
		if paras.is_a?(Service)
			paras = {
				"service" => paras,
				"pluginname" => paras["plugin"]
			}
		end
		
		if !paras["plugin"] and paras["pluginname"]
			classob = ServiceWatcher.plugin_class(paras["pluginname"])
			if classob.respond_to?("check")
				staticmethod = true
			else
				paras["plugin"] = classob.new(paras["service"].details)
			end
		end
		
		begin
			if staticmethod
				classob.check(paras["service"].details)
			else
				paras["plugin"].check
			end
			
			return {
				"errorstatus" => false
			}
		rescue Exception => e
			paras["service"].reporters_merged.each do |reporter|
				reporter.reporter_plugin.report_error("reporter" => reporter, "error" => e, "pluginname" => paras["pluginname"], "plugin" => paras["plugin"], "service" => paras["service"])
			end
			
			return {
				"errorstatus" => true,
				"error" => e
			}
		end
	end
	
	def self.parse_subject(paras)
		subject = paras["subject"].gsub("%subject%", paras["error"].inspect.to_s)
		return subject
	end
end