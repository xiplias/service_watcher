class Service_watcher::Reporter < Knj::Datarow
  def self.list(d)
    sql = "SELECT * FROM #{table} WHERE 1=1"
    
    ret = list_helper(d)
    d.args.each do |key, val|
        raise sprintf(_("Invalid key: %s."), key)
    end
    
    sql += ret[:sql_where]
    sql += ret[:sql_order]
    sql += ret[:sql_limit]
    
    return d.ob.list_bysql(:Reporter, sql)
  end
  
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
    db.delete("reporters_options", {"reporter_id" => self["id"]})
  end
  
  def details
    data = {}
    q_details = db.select(:reporters_options, {"reporter_id" => self["id"]})
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