class Service_watcher::Plugin::Ssh_swapping < Service_watcher::Plugin
  def self.paras
    return [{
      "title" => _("Hostname"),
      "name" => "txthost"
    },{
      "title" => _("Port"),
      "name" => "txtport",
      "default" => "22"
    },{
      "title" => _("Username"),
      "name" => "txtuser"
    },{
      "type" => "password",
      "title" => _("Password"),
      "name" => "txtpasswd"
    }]
  end
end