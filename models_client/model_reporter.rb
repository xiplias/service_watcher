class Service_watcher::Client::Model::Reporter < Service_watcher::Client::Model
  init_sw_model(self)
  
  def options
    return _sw.request(:c => :reporter, :a => :options, :reporter_id => id)
  end
end