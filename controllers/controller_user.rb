class Service_watcher::Controllers::User < Service_watcher::Controller
  def login
    user = _ob.get_by(:User, {
      "username" => _get["username"],
      "password" => _get["password"]
    })
    
    raise _("A user with that username and/or password could not be found.") if !user
    _session[:user_id] = user.id
    
    return {
      :user_id => user.id
    }
  end
end