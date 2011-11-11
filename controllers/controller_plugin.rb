class Service_watcher::Controllers::Plugin < Service_watcher::Controller
  def list
    return _sw.plugins
  end
  
  def args
    return Service_watcher::Plugin.const_get(Knj::Php.ucwords(_get["plugin_name"])).paras
  end
end