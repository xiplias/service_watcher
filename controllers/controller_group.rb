class Service_watcher::Controllers::Group < Service_watcher::Controller
  def add
    group = _ob.add(:Group, {
      :name => _get["name"]
    })
    
    return {
      :id => group.id,
      :name => group.name
    }
  end
  
  def add_reporter
    group = _ob.get(:Group, _get["group_id"])
    reporter = _ob.get(:Reporter, _get["reporter_id"])
    
    link = _ob.get_by(:Group_reporterlink, {
      "group" => group,
      "reporter" => reporter
    })
    raise _("That reporter is already member of that group.") if link
    
    link = _ob.add(:Group_reporterlink, {
      :group_id => group.id,
      :reporter_id => reporter.id
    })
    
    return {
      :group_reporterlink_id => link.id
    }
  end
  
  def list
    ret = []
    
    _ob.list(:Group, _get["args"]) do |group|
      ret << group.client_data
    end
    
    return ret
  end
  
  def get
    group = _ob.get(:Group, _get["group_id"])
    return group.client_data
  end
  
  def update
    group = _ob.get(:Group, _get["group_id"])
    group.update(
      :name => _get["name"]
    )
    return group.client_data
  end
  
  def delete
    group = _ob.get(:Group, _get["group_id"])
    _ob.delete(group)
    return {}
  end
  
  def services
    group = _ob.get(:Group, _get["group_id"])
    
    ret = []
    group.services(_get["args"]).each do |service|
      ret << service.client_data
    end
    
    return ret
  end
  
  def reporters
    group = _ob.get(:Group, _get["group_id"])
    
    ret = []
    group.reporters.each do |link|
      ret << link.reporter.client_data if link.reporter
    end
    
    return ret
  end
  
  def add_reporter
    link = _ob.add(:Group_reporterlink, {
      :group_id => _get["group_id"],
      :reporter_id => _get["reporter_id"]
    })
    return {}
  end
  
  def remove_reporter
    link = _ob.get_by(:Group_reporterlink, {
      "group_id" => _get["group_id"],
      "reporter_id" => _get["reporter_id"]
    })
    _ob.delete(link) if link
    return {}
  end
end