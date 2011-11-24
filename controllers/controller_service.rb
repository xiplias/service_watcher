class Service_watcher::Controllers::Service < Service_watcher::Controller
  def list
    list = []
    _ob.list(:Service, _get["args"]) do |service|
      list << service.client_data
    end
    
    return list
  end
  
  def add
    service = _ob.add(:Service, {
      :name => _get["name"],
      :plugin => _get["plugin"],
      :group_id => _get["group_id"],
      :timeout => _get["timeout"]
    })
    
    return service.client_data
  end
  
  def get
    service = _ob.get(:Service, _get["service_id"])
    return service.client_data
  end
  
  def update
    service = _ob.get(:Service, _get["service_id"])
    service.update(
      :name => _get["name"],
      :plugin => _get["plugin"],
      :timeout => _get["timeout"],
      :group_id => _get["group_id"]
    )
    return service.client_data
  end
  
  def delete
    service = _ob.get(:Service, _get["service_id"])
    _ob.delete(service)
    return {}
  end
  
  def update_options
    service = _ob.get(:Service, _get["service_id"])
    
    if _get["options"].is_a?(Hash)
      found = {}
      _get["options"].each do |key, val|
        found[key] = true
        
        data = {
          "object_class" => "Service",
          "object_id" => service.id,
          "key" => key,
          "value" => val
        }
        
        option = _ob.get_by(:Option, {
          "object_class" => "Service",
          "object_id" => service.id,
          "key" => key
        })
        
        if !option
          option = _ob.add(:Option, data)
        else
          option.update(data)
        end
      end
    end
    
    service.options.each do |option|
      next if found.key?(option[:key])
      _ob.delete(option)
    end
  end
  
  def options
    service = _ob.get(:Service, _get["service_id"])
    return service.details
  end
  
  def check
    service = _ob.get(:Service, _get["service_id"])
    return service.check
  end
end