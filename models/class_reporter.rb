class Service_watcher::Reporter < Knj::Datarow
  def delete
    self.groups.each do |link|
      ob.delete(link)
    end
    
    self.services.each do |link|
      ob.delete(link)
    end
    
    self.del_details
  end
  
  def del_details
    db.delete("reporters_options", {"reporter_id" => id})
  end
  
  def details
    data = {}
    q_details = db.select(:reporters_options, {"reporter_id" => id})
    while(d_details = q_details.fetch)
      data[d_details[:opt_name]] = d_details[:opt_value]
    end
    
    return data
  end
  
  def add_detail(name, value)
    db.insert(:reporters_options, {"reporter_id" => self["id"], "opt_name" => name, "opt_value" => value})
  end
  
  def reporter_plugin
    obj_name = "ServiceWatcherReporter" + Knj::Php::ucwords(self["plugin"])
    return Kernel.const_get(obj_name).new(self.details)
  end
  
  alias plugin reporter_plugin
  
  def groups(args = {})
    return ob.list(:Group_reporterlink, {"reporter" => self}.merge(args))
  end
  
  def services
    return ob.list(:Service_reporterlink, {"reporter" => self}.merge(args))
  end
end