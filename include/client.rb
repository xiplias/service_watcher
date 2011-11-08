class Service_watcher::Client
  def initialize(args)
    @http = Knj::Http2.new(
      :host => args[:host],
      :port => args[:port],
      :ssl => args[:ssl]
    )
  end
  
  def login(args)
    return self.request(:c => :user, :a => :login, :username => args[:username], :password => Digest::MD5.hexdigest(args[:password]))
  end
  
  def request(args)
    url = "?"
    args.each do |key, val|
      url += "&" if url != "?"
      url += "#{Knj::Web.urlenc(key)}=#{Knj::Web.urlenc(val)}"
    end
    
    res = @http.get(url)
    ret = JSON.parse(res.body)
    raise Kernel.const_get(ret["error_type"]), ret["error_msg"] if ret["type"] == "error"
    
    return ret["data"]
  end
end