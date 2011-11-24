class Service_watcher::Plugin::Ssh_file_exists < Service_watcher::Plugin
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
    },{
      "title" => _("Path"),
      "name" => "txtpath"
    },{
      "title" => _("Filename regex"),
      "name" => "txtfnregex"
    },{
      :title => _("Replaces"),
      :type => :plain,
      :value =>
        "#{_("%Y will be replaced by 4-digit year.")}\n" +
        "#{_("%m will be replaced by 2-digit month.")}\n" +
        "#{_("%d will be replaced by 2-digit date.")}\n" +
        "#{_("%yday will be replaced by 2-digit of yesterdays date.")}"
    }]
  end
  
  def self.check(paras)
    require "knj/sshrobot"
    require "knj/cmd_parser"
    
    sshrobot = nil
    Timeout.timeout(10) do
      sshrobot = Knj::SSHRobot.new(
        "host" => paras["txthost"],
        "port" => paras["txtport"].to_i,
        "user" => paras["txtuser"],
        "passwd" => paras["txtpasswd"]
      )
    end
    
    date = Knj::Datet.new
    yday = date.days - 1
    
    regex = paras["txtfnregex"]
    regex.gsub!("%Y", date.year.to_s)
    regex.gsub!("%m", "%02d" % date.month)
    regex.gsub!("%d", "%02d" % date.date)
    regex.gsub!("%yday", "%02d" % yday.date)
    
    regex_obj = Regexp.compile(regex)
    
    match = nil
    output = sshrobot.exec("ls -lh #{Knj::Strings::UnixSafe(paras["txtpath"])}")
    entries = Knj::Cmd_parser.lsl(output)
    entries.each do |entry|
      if match = entry[:file].to_s.match(regex_obj)
        break
      end
    end
    
    raise sprintf(_("Nothing was matched from regex: '%s'."), regex) + "\n\n#{output}" if !match
  end
end