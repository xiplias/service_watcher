class Service_watcher::Client::Model::Service < Service_watcher::Client::Model
  init_sw_model(self)
  
  def options
    return _sw.request(:c => :service, :a => :options, :service_id => id)
  end
end