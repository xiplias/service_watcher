class Service_watcher::Group_reporterlink < Knj::Datarow
  def self.add(d)
    group = ob.get(:Group, d.data[:group_id])
    reporter = ob.get(:Reporter, d.data[:reporter_id])
    
    link = d.ob.list(:Group_reporterlink, {"group" => group, "reporter" => reporter})
    if link.length > 0
      raise Errors::Notice, _("Such a reporter is already added to that group.")
    end
  end
  
  def self.list(d)
    sql = "SELECT * FROM #{table} WHERE 1=1"
    
    ret = list_helper(d)
    d.args.each do |key, val|
      raise sprintf(_("Invalid key: %s."), key)
    end
    
    sql += ret[:sql_where]
    sql += ret[:sql_order]
    sql += ret[:sql_limit]
    
    return d.ob.list_bysql(:Group_reporterlink, sql)
  end
  
  def group
    return ob.get(:Group, self[:group_id])
  end
  
  def reporter
    return ob.get(:Reporter, self[:reporter_id])
  end
  
  def title
    return self.reporter.title
  end
end