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
  end
end