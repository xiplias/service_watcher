class Service_watcher::Client
  class Model < Knj::Datarow_custom
    def self.controller_name
      return self.name.to_s.match(/::([^:]+?)$/)[1].downcase
    end
    
    def self.class_name
      return self.name.to_s.match(/::([^:]+?)$/)[1].to_sym
    end
    
    def self.init_sw_model(classobj)
      classobj.events.connect(:add) do |event, d|
        data = _sw.request({:c => self.controller_name, :a => :add}.merge(d.data))
        _ob.get(self.class_name, data)
      end
      
      classobj.events.connect(:update) do |event, d|
        _sw.request({:c => self.controller_name, :a => :update, "#{self.controller_name}_id" => d.object.id}.merge(d.data))
      end
      
      classobj.events.connect(:data_from_id) do |event, d|
        data = _sw.request(:c => self.controller_name, :a => :get, "#{self.controller_name}_id" => d.id)
        raise _("No data received?") if !data
        data
      end
      
      classobj.events.connect(:delete) do |event, d|
        _sw.request(:c => self.controller_name, :a => :delete, "#{self.controller_name}_id" => d.object.id)
      end
    end
    
    def self.list(d)
      ret = []
      _sw.request(:c => self.controller_name, :a => :list, :args => d.args).each do |data|
        ret << _ob.get(self.class_name, data)
      end
      
      return ret
    end
    
    def url
      return "/?s=#{self.class.controller_name}_view&#{self.class.controller_name}_id=#{self.id}"
    end
    
    def url_edit
      return "/?s=#{self.class.controller_name}_edit&#{self.class.controller_name}_id=#{self.id}"
    end
    
    def html
      return "<a href=\"#{self.url}\">#{self.name.html}</a>"
    end
  end
  
  #Initializes the HTTP-connection to the server with the given arguments.
  def initialize(args)
    require "http2"
    require "json"
    
    @http = Http2.new(
      :host => args[:host],
      :port => args[:port],
      :ssl => args[:ssl]
    )
  end
  
  #Logs in with username and password on the server. ':password'-argument should be MD5-hashed from the plain value.
  def login(args)
    return self.request(:c => :user, :a => :login, :username => args[:username], :password => args[:password])
  end
  
  #Used to recursively convert hash- and array-arguments to a valid Knjappserver-URL-arguments-string. No need to call this manually - it is used from the request-method.
  def args_rec(orig_key, obj, first)
    url = ""
    first_ele = true
    
    if obj.is_a?(Array)
      ele_count = 0
      
      obj.each do |val|
        orig_key_str = "#{orig_key}[#{ele_count}]"
        val = "#<Model::#{val.table}::#{val.id}>" if val.is_a?(Service_watcher::Client::Model)
        
        if val.is_a?(Hash) or val.is_a?(Array)
          url += self.args_rec(orig_key_str, val, false)
        else
          url += "&" if !first or !first_ele
          url += "#{orig_key_str}=#{Knj::Web.urlenc(val)}"
        end
        
        first_ele = false if first_ele
        ele_count += 1
      end
    elsif obj.is_a?(Hash)
      obj.each do |key, val|
        if first
          orig_key_str = key
        else
          orig_key_str = "#{orig_key}[#{key}]"
        end
        
        val = "#<Model::#{val.table}::#{val.id}>" if val.is_a?(Service_watcher::Client::Model)
        
        if val.is_a?(Hash) or val.is_a?(Array)
          url += self.args_rec(orig_key_str, val, false)
        else
          url += "&" if !first or !first_ele
          url += "#{Knj::Web.urlenc(orig_key_str)}=#{Knj::Web.urlenc(val)}"
        end
        
        first_ele = false if first_ele
      end
    else
      raise "Unknown class: '#{obj.class.name}'."
    end
    
    return url
  end
  
  #Sends request to server and return the data. If an error occurred on the server that error will be thrown as if the error occurred on the client.
  def request(args)
    url = "?#{self.args_rec("", args, true)}"
    
    res = @http.get(:url => "index.rhtml#{url}")
    raise ArgumentError, _("Server returned an empty response. An error probaly occurred on the server.") if res.body.strip.length <= 0
    
    begin
      ret = JSON.parse(Php4r.gzuncompress(res.body))
    rescue JSON::ParserError, Zlib::DataError => e
      _kas.dprint "Could parse JSON from:\n\n#{res.body}\n\n"
      raise e
    rescue => e
      _kas.dprint "Error when parsing content from server."
      
      _kas.dprint "\nHeaders:"
      _kas.dprint res.headers
      
      _kas.dprint "\nBody:"
      _kas.dprint res.body
      _kas.dprint "\n\n"
      
      STDOUT.puts e.inspect
      STDOUT.puts e.backtrace
      
      STDOUT.print "\n\n"
      
      raise e
    end
    
    if ret["type"] == "error"
      begin
        begin
          const = Knj::Strings.const_get_full(ret["error_type"])
        rescue NameError
          raise ret["error_msg"]
        end
        
        raise const, ret["error_msg"]
      rescue Exception => e
        #Add the backtrace from the server so it is easier to debug.
        e.set_backtrace(ret["error_backtrace"] | e.backtrace)
        raise e
      end
    end
    
    return ret["data"]
  end
end