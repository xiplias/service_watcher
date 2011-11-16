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
    
    _ob.list(:Group) do |group|
      ret << {
        :id => group.id,
        :name => group.name
      }
    end
    
    return ret
  end
  
  def get
    group = _ob.get(:Group, _get["group_id"])
    
    return {
      :id => group.id,
      :name => group.name
    }
  end
  
  def update
    group = _ob.get(:Group, _get["group_id"])
    group.update(
      :name => _get["name"]
    )
  end
end