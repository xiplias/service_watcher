class Service_watcher::Client
  #Initializes the HTTP-connection to the server with the given arguments.
  def initialize(args)
    @http = Knj::Http2.new(
      :host => args[:host],
      :port => args[:port],
      :ssl => args[:ssl]
    )
  end
  
  #Logs in with username and password on the server.
  def login(args)
    return self.request(:c => :user, :a => :login, :username => args[:username], :password => Digest::MD5.hexdigest(args[:password]))
  end
  
  #Used to recursively convert hash- and array-arguments to a valid Knjappserver-URL-arguments-string. No need to call this manually - it is used from the request-method.
  def args_rec(orig_key, obj)
    url = ""
    
    if obj.is_a?(Array)
      obj.each do |val|
        url += "&"
        
        if val.is_a?(Hash) or val.is_a?(Array)
          url += self.args_rec("#{orig_key}[]", val)
        else
          url += "#{Knj::Web.urlenc("#{orig_key}[]")}=#{Knj::Web.urlenc(val)}"
        end
      end
    elsif obj.is_a?(Hash)
      obj.each do |key, val|
        url += "&"
        
        if val.is_a?(Hash) or val.is_a?(Array)
          url += self.args_rec("#{orig_key}[#{key}]", val)
        else
          url += "#{Knj::Web.urlenc("#{orig_key}[#{key}]")}=#{Knj::Web.urlenc(val)}"
        end
      end
    else
      raise "Unknown class: '#{obj.class.name}'."
    end
    
    return url
  end
  
  #Sends request to server and return the data. If an error occurred on the server that error will be thrown as if the error occurred on the client.
  def request(args)
    url = "?"
    args.each do |key, val|
      url += "&" if url != "?"
      
      if val.is_a?(Hash) or val.is_a?(Array)
        url += self.args_rec(key, val)
      else
        url += "#{Knj::Web.urlenc(key)}=#{Knj::Web.urlenc(val)}"
      end
    end
    
    res = @http.get(url)
    ret = JSON.parse(res.body)
    
    if ret["type"] == "error"
      begin
        raise Knj::Strings.const_get_full(ret["error_type"]), ret["error_msg"]
      rescue Exception => e
        #Add the backtrace from the server so it is easier to debug.
        e.set_backtrace(ret["error_backtrace"] | e.backtrace)
        raise e
      end
    end
    
    return ret["data"]
  end
end