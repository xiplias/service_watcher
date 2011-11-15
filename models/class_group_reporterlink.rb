class Service_watcher::Model::Group_reporterlink < Knj::Datarow
  def self.add(d)
    group = d.ob.get(:Group, d.data[:group_id])
    reporter = d.ob.get(:Reporter, d.data[:reporter_id])
    
    link = d.ob.list(:Group_reporterlink, {"group" => group, "reporter" => reporter})
    if link.length > 0
      raise Errors::Notice, _("Such a reporter is already added to that group.")
    end
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