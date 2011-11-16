class Service_watcher::Client::Model::Group < Service_watcher::Client::Model
  init_sw_model(self)
  
  def services
    service_data = _sw.request(:c => :group, :a => :services, :group_id => self.id)
    
    ret = []
    service_data.each do |service_d|
      ret << _ob.get(:Service, service_d)
    end
    
    return ret
  end
end