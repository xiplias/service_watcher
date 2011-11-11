class Service_watcher::Controllers::Service < Service_watcher::Controller
  def list
    list = []
    _ob.list(:Service) do |service|
      list << {
        :name => service.name,
        :plugin => service[:plugin]
      }
    end
    
    return list
  end
  
  def add
    service = _ob.add(:Service, {
      :name => _get["name"],
      :plugin => _get["plugin"]
    })
    
    self.save_options(service)
    
    return {
      :service_id => service.id
    }
  end
  
  def update
    service = _ob.get(:Service, _get["service_id"])
    service.update(
      :name => _get["name"],
      :plugin => _get["plugin"]
    )
    self.save_options(service)
  end
  
  def save_options(service)
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
  
  def check
    service = _ob.get(:Service, _get["service_id"])
    return service.check
  end
end