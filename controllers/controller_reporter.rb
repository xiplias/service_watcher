class Service_watcher::Controllers::Reporter < Service_watcher::Controller
  def plugins
    return _sw.reporters
  end
  
  def plugins_opts
    reporters = _sw.reporters
    
    ret = {}
    reporters.each do |name, data|
      ret[name] = data[:name]
    end
    
    return ret
  end
  
  def plugin_args
    return Service_watcher::Reporter.const_get(Php4r.ucwords(_get["plugin_name"])).paras
  end
  
  def list
    ret = []
    _ob.list(:Reporter) do |reporter|
      ret << reporter.client_data
    end
    
    return ret
  end
  
  def add
    reporter = _ob.add(:Reporter, {
      :name => _get["name"],
      :plugin => _get["plugin"]
    })
    
    return reporter.client_data
  end
  
  def update
    reporter = _ob.get(:Reporter, _get["reporter_id"])
    reporter.update(
      :name => _get["name"],
      :plugin => _get["plugin"]
    )
    return reporter.client_data
  end
  
  def get
    reporter = _ob.get(:Reporter, _get["reporter_id"])
    return reporter.client_data
  end
  
  def delete
    reporter = _ob.get(:Reporter, _get["reporter_id"])
    _ob.delete(reporter)
    return {}
  end
  
  def update_options
    reporter = _ob.get(:Reporter, _get["reporter_id"])
    
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
  
  def options
    reporter = _ob.get(:Reporter, _get["reporter_id"])
    return reporter.details
  end
  
  def args
    return Service_watcher::Reporter.const_get(Php4r.ucwords(_get["reporter_name"])).paras
  end
end