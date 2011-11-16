require "knj/datarow_custom"

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
      raise "args are not yet supported." if d.args.length > 0
      
      ret = []
      _sw.request(:c => self.controller_name, :a => :list).each do |data|
        ret << _ob.get(self.class_name, data)
      end
      
      return ret
    end
    
    def url
      return "/?s=#{self.class.controller_name}_view&#{self.class.controller_name}_id=#{self.id}"
    end
    
    def html
      return "<a href=\"#{self.url}\">#{self.name.html}</a>"
    end
  end
  
  #Initializes the HTTP-connection to the server with the given arguments.
  def initialize(args)
    require "knj/http2"
    require "knj/strings"
    require "knj/autoload/json_autoload"
    
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