class Service_watcher::Controllers::Reporter < Service_watcher::Reporter
  def list
    return _sw.reporters
  end
  
  def add
    reporter = _ob.add(:Reporter, {
      :name => _get["name"],
      :plugin => _get["plugin"]
    })
    
    self.save_options(reporter)
    
    return {
      :reporter_id => reporter.id
    }
  end
  
  def save_options(reporter)
    if _get["options"].is_a?(Hash)
      found = {}
      _get["options"].each do |key, val|
        found[key] = true
        
        data = {
          "object_class" => "Reporter",
          "object_id" => reporter.id,
          "key" => key,
          "value" => val
        }
        
        option = _ob.get_by(:Option, {
          "object_class" => "Reporter",
          "object_id" => reporter.id,
          "key" => key
        })
        
        if !option
          option = _ob.add(:Option, data)
        else
          option.update(data)
        end
      end
    end
    
    reporter.options.each do |option|
      next if found.key?(option[:key])
      _ob.delete(option)
    end
  end
  
  def args
    return Service_watcher::Reporter.const_get(Knj::Php.ucwords(_get["reporter_name"])).paras
  end
end