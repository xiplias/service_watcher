class Service_watcher::Plugin::Ssh_mailsupport < Service_watcher::Plugin
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
      "title" => _("Send to address"),
      "name" => "txtsendto"
    },{
      "title" => _("IMAP host"),
      "name" => "txtimaphost"
    },{
      "title" => _("IMAP port"),
      "name" => "txtimapport"
    },{
      "title" => "SSL",
      "name" => "cheimapssl"
    },{
      "title" => _("IMAP username"),
      "name" => "txtimapusername"
    },{
      "title" => _("IMAP password"),
      "name" => "txtimappassword",
      "type" => :password
    }]
  end
  
  def self.check(paras)
    found = false
    
    require "digest"
    code = Digest::MD5.hexdigest(Time.now.to_f.to_s)
    
    #Knj::Retry.try(:tries => 3, :timeout => 15, :wait => 2, :errors => [Errno::ETIMEDOUT, Errno::EHOSTUNREACH]) do
      Knj::SSHRobot.new(
        "host" => paras["txthost"],
        "port" => paras["txtport"].to_i,
        "user" => paras["txtuser"],
        "passwd" => paras["txtpasswd"]
      ) do |sshrobot|
        output = sshrobot.exec("echo \"#{code}\" | mail -s ServiceWatcherTest \"#{paras["txtsendto"]}\"")
        print output
      end
      
      require "net/imap"
      if paras["cheimapssl"] == "on"
        ssl = true
      else
        ssl = false
      end
      
      #Give the host a bit time to receive the email.
      sleep 10
      
      conn = Net::IMAP.new(paras["txtimaphost"], paras["txtimapport"].to_i, ssl)
      
      begin
        conn.login(paras["txtimapusername"], paras["txtimappassword"])
        
        conn.select("INBOX")
        emails = conn.search(["ALL"])
        emails.each do |msg_id|
          body = conn.fetch(msg_id, "BODY[TEXT]")[0].attr["BODY[TEXT]"]
          env = conn.fetch(msg_id, "ENVELOPE")[0].attr["ENVELOPE"]
          subject = env.subject
          
          #Skip if the email doesnt have the right subject.
          next if subject.to_s.strip != "ServiceWatcherTest"
          
          #Mark found as true if the email has the right code.
          found = true if body.to_s.strip == code
          
          #Delete email from server.
          conn.store(msg_id, "+FLAGS", [:Deleted])
          
          #Prints for debugging.
          #STDOUT.print "Subject: #{subject}\n"
          #STDOUT.print "Body: #{body.to_s.strip}\n"
          #STDOUT.print "Search for: #{code}\n"
          #STDOUT.print "\n"
        end
        
        #Send deletes to server.
        conn.expunge
      ensure
        begin
          conn.logout
          conn.disconnect
        rescue Net::IMAP::NoResponseError, Net::IMAP::ByeResponseError
          #discard
        end
      end
    #end
    
    raise _("Could not find the test-email on the given account.") if !found
  end
end