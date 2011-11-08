class Service_watcher::Controllers::Plugin < Service_watcher::Controller
  def list
    return _sw.plugins
  end
end