class Service_watcher::Controllers::Plugin < Service_watcher::Controller
  def list
    return _sw.plugins
  end
  
  def list_opts
    ret = {}
    _sw.plugins.each do |name, data|
      ret[name] = data[:name]
    end
    
    ret_sorted = ret.sort do |a, b|
      a[1] <=> b[1]
    end
    
    ret = {}
    ret_sorted.each do |data|
      ret[data[0]] = data[1]
    end
    
    return ret
  end
  
  def args
    return Service_watcher::Plugin.const_get(Php4r.ucwords(_get["plugin_name"])).paras
  end
end