class Service_watcher::Controllers::Log < Service_watcher::Controller
  def list
    logs = _hb.ob.list(:Log, _get["args"])
    
    ret = []
    logs.each do |log|
      ret << self.client_data(log)
    end
    
    return ret
  end
  
  def get
    log = _hb.ob.get(:Log, _get["object_id"])
    return self.client_data(log)
  end
  
  def client_data(log)
    return {
      :id => log.id,
      :text => log.text,
      :comment => log.comment,
      :tag => log.tag,
      :date_saved_str => log.date_saved_str
    }
  end
end