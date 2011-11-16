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
  
  def reporters
    reporters_data = _sw.request(:c => :group, :a => :reporters, :group_id => self.id)
    
    ret = []
    reporters_data.each do |reporter_d|
      ret << _ob.get(:Reporter, reporter_d)
    end
    
    return ret
  end
  
  def add_reporter(reporter)
    _sw.request(:c => :group, :a => :add_reporter, :group_id => self.id, :reporter_id => reporter.id)
  end
  
  def remove_reporter(reporter)
    _sw.request(:c => :group, :a => :remove_reporter, :group_id => self.id, :reporter_id => reporter.id)
  end
end