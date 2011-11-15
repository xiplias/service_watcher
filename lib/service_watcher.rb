require "knjrbfw"
require "knj/autoload"

class Service_watcher
  attr_reader :appserver, :controllers, :db, :ob, :plugins, :reporters
  
  class Controllers; end
  class Plugin; end
  class Reporter; end
  class Model; end
  
  def initialize(args = {})
    @plugins = {}
    
    path = "#{File.dirname(__FILE__)}/../"
    require "#{path}/include/controller.rb"
    require "#{path}/include/client.rb"
    
    plugins_path = "#{path}/plugins"
    Dir.foreach(plugins_path) do |plugin_file|
      if plugin_file != "." and plugin_file != ".."
        require "#{plugins_path}/#{plugin_file}" if plugin_file != "." and plugin_file != ".."
        plugin_name = plugin_file.slice(28..-4)
        @plugins[plugin_name] = {
          :name => plugin_name,
          :class => Service_watcher::Plugin.const_get(Knj::Php.ucwords(plugin_name))
        }
        
        #autoload(("ServiceWatcherPlugin" + Knj::Php.ucwords(plugin_file.slice(28..-4))).to_sym, plugins_path + "/" + plugin_file)
      end
    end
    
    @reporters = {}
    
    reporters_path = "#{path}/reporters"
    Dir.foreach(reporters_path) do |reporter_file|
      next if reporter_file == "." or reporter_file == ".."
      require "#{reporters_path}/#{reporter_file}"
      
      reporter_name = Knj::Php.ucwords(reporter_file.slice(30..-4))
      @reporters[reporter_name] = {
        :name => reporter_name,
        :class => Service_watcher::Reporter.const_get(Knj::Php.ucwords(reporter_name))
      }
    end
    
    #Make arguments array and merge with the given arguments.
    @args = {
      :port => 80,
      :host => "0.0.0.0"
    }.merge(args)
    
    
    #Spawn primary database.
    if args[:db]
      @db = args[:db]
    elsif args[:db_args]
      @db = Knj::Db.new(@args[:db_args])
    else
      raise "No database given in any form."
    end
    
    #Make sure database is updated.
    dbschemapath = "#{File.dirname(__FILE__)}/../files/database_schema.rb"
    raise "'#{dbschemapath}' did not exist." if !File.exists?(dbschemapath)
    require dbschemapath
    raise "No schema-variable was spawned." if !$schema
    dbrev = Knjdbrevision.new
    dbrev.init_db($schema, @db)
    
    
    #Spawn objects-handler.
    @ob = Knj::Objects.new(
      :db => @db,
      :class_path => "#{File.dirname(__FILE__)}/../models",
      :module => Service_watcher::Model,
      :datarow => true,
      :require_all => true
    )
    
    
    #Load all the controllers.
    @controllers = {}
    controllers_path = "#{File.dirname(__FILE__)}/../controllers"
    Dir.foreach(controllers_path) do |controller_file|
      match = controller_file.match(/^controller_(.+)\.rb$/)
      next if !match
      
      require "#{controllers_path}/#{controller_file}"
      @controllers[match[1].downcase] = Service_watcher::Controllers.const_get(Knj::Php.ucwords(match[1])).new(:sw => self)
    end
    
    
    #Spawn the appserver.
    appserver_args = {
      :debug => false,
      :autorestart => false,
      :title => "Service_watcher",
      :port => @args[:port],
      :host => @args[:host],
      :doc_root => "#{File.dirname(__FILE__)}/../json_pages",
      :hostname => false,
      :error_report_emails => [@args[:admin_email]],
      :error_report_from => @args[:admin_email],
      :locales_root => "#{File.dirname(__FILE__)}/../locales",
      :locales_gettext_funcs => true,
      :locale_default => "en_GB",
      :db => @db,
      :smtp_args => @args[:smtp]
    }
    appserver_args.merge(@args[:knjappserver_args]) if @args.key?(:knjappserver_args)
    @appserver = Knjappserver.new(appserver_args)
    
    
    #Define various variables which should be available in the various controllers.
    @appserver.define_magic_var(:_sw, self)
    @appserver.define_magic_var(:_ob, @ob)
    
    
    #Start main thread that runs service-checks automatically based on timeouts.
    @thread = Knj::Thread.new do
      self.service_checker
    end
    
    #Start the appserver.
    @appserver.start
  end
  
  def service_checker
    loop do
      Thread.current[:running] = true
      @ob.list(:Service) do |service|
        run = false
        cur_time = Time.new.to_i
        service_date = service.date_lastrun
        
        if !service_date
          run = true
        else
          service_time = service_date.time.to_i
          if (service_time + service[:timeout].to_i) < cur_time
            run = true
          end
        end
        
        self.check_and_report(service) if run
      end
      Thread.current[:running] = false
      
      sleep 1
    end
  end
  
  def check_and_report(args)
    staticmethod = false
    
    if args.is_a?(Service_watcher::Model::Service)
      args = {
        "service" => args,
        "pluginname" => args[:plugin]
      }
    end
    
    if !args["plugin"] and args["pluginname"]
      classob = Service_watcher::Plugin.const_get(Knj::Php.ucwords(args["pluginname"]))
      if classob.respond_to?("check")
        staticmethod = true
      else
        args["plugin"] = classob.new(args["service"].details)
      end
    end
    
    args["service"][:date_lastrun] = Time.now if args["service"]
    
    begin
      if staticmethod
        classob.check(args["service"].details)
      else
        args["plugin"].check
      end
      
      return {
        "errorstatus" => false
      }
    rescue Exception => e
      args["service"].reporters_merged.each do |reporter|
        reporter.reporter_plugin.report_error("reporter" => reporter, "error" => e, "pluginname" => args["pluginname"], "plugin" => args["plugin"], "service" => args["service"])
      end
      
      return {
        "errorstatus" => true,
        "error" => e
      }
    end
  end
  
  def self.parse_subject(args)
    subject = args["subject"].gsub("%subject%", args["error"].inspect.to_s)
    return subject
  end
  
  #Stops the service-watcher gracefully. Stops the knjappserver and lets the checker-thread finish before killing it.
  def stop
    @appserver.stop
    
    if @thread
      sleep 0.1 while @thread[:running]
      @thread.kill
      @thread = nil
    end
  end
end