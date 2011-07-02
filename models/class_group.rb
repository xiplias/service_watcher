class Service_watcher::Group < Knj::Datarow
  def self.list(d)
    sql = "SELECT * FROM groups WHERE 1=1"
    
    ret = list_helper(d)
    d.args.each do |key, val|
      raise sprintf(_("Invalid key: %s."), key)
    end
    
    sql += ret[:sql_where]
    sql += ret[:sql_order]
    sql += ret[:sql_limit]
    
    return d.ob.list_bysql(:Group, sql)
  end
  
  def services(args = {})
    return ob.list(:Service, {"group" => self}.merge(args))
  end
  
  def reporters(args = {})
    return ob.list(:Group_reporterlink, {"group" => self}.merge(args))
  end
  
  def name
    return self[:name]
  end
end