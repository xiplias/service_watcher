class Service_watcher
  attr_reader :appserver, :controllers, :db, :ob, :plugins, :reporters
  
  #Autoloader for subclasses.
  def self.const_missing(name)
    require "#{File.dirname(__FILE__)}/../include/#{name.to_s.downcase}.rb"
    raise "Still not defined: '#{name}'." if !Service_watcher.const_defined?(name)
    return Service_watcher.const_get(name)
  end
  
  class Controllers; end
  class Plugin; end
  class Reporter; end
  class Model; end
  
  def self.path
    return File.dirname(__FILE__)
  end
  
  def initialize(args = {})
    #Make arguments array and merge with the given arguments.
    @args = {
      :port => 80,
      :host => "0.0.0.0"
    }.merge(args)
    
    require "rubygems"
    require "#{@args[:knjappserver_path]}knjappserver"
    require "#{@args[:knjrbfw_path]}knjrbfw"
    require "php4r"
    require "json"
    require "net/http"
    
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
          :class => Service_watcher::Plugin.const_get(Php4r.ucwords(plugin_name))
        }
        
        #autoload(("ServiceWatcherPlugin" + Php4r.ucwords(plugin_file.slice(28..-4))).to_sym, plugins_path + "/" + plugin_file)
      end
    end
    
    @reporters = {}
    
    reporters_path = "#{path}/reporters"
    Dir.foreach(reporters_path) do |reporter_file|
      next if reporter_file == "." or reporter_file == ".."
      require "#{reporters_path}/#{reporter_file}"
      
      reporter_name = Php4r.ucwords(reporter_file.slice(30..-4))
      @reporters[reporter_name] = {
        :name => reporter_name,
        :class => Service_watcher::Reporter.const_get(Php4r.ucwords(reporter_name))
      }
    end
    
    
    #Spawn primary database.
    if args[:db]
      @db = args[:db]
    elsif args[:db_args]
      @db = Knj::Db.new(@args[:db_args])
    else
      raise "No database given in any form."
    end
    
    #Make sure database is updated.
<<<<<<< HEAD
    dbschemapath = "#{File.dirname(__FILE__)}/../files/database_schema.rb"
    raise "'#{dbschemapath}' did not exist." if !File.exists?(dbschemapath)
    require dbschemapath
    raise "No schema-variable was spawned." if !$schema
    Knj::Db::Revision.new.init_db("schema" => $schema, "db" => @db)
=======
    Knj::Db::Revision.new.init_db("schema" => Service_watcher::Database::SCHEMA, "db" => @db)
>>>>>>> 70f823b4859be4fca85cc761ab8c0176b2c2f573
    
    
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
      class_obj = Service_watcher::Controllers.const_get(Php4r.ucwords(match[1]))
      raise "Not a controller: '#{class_obj}' (superclass: #{class_obj.superclass.name})." if class_obj.superclass.name != "Service_watcher::Controller"
      @controllers[match[1].downcase] = class_obj.new(:sw => self)
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
    appserver_args[:knjrbfw_path] = @args[:knjrbfw_path] if @args.key?(:knjrbfw_path)
    appserver_args.merge!(@args[:knjappserver_args]) if @args.key?(:knjappserver_args)
    @appserver = Knjappserver.new(appserver_args)
    
    
    #Define various variables which should be available in the various controllers.
    @appserver.define_magic_var(:_sw, self)
    @appserver.define_magic_var(:_ob, @ob)
    
    
    #Start main thread that runs service-checks automatically based on timeouts.
    @thread = Knj::Thread.new(&self.method(:service_checker))
    
    #Start the appserver.
    @appserver.start
  end
  
  def service_checker
    @appserver.thread_init
    
    loop do
      Thread.current[:running] = true
      @ob.list(:Service) do |service|
        run = false
        service_date = service.date_lastrun
        
        if !service_date
          run = true
        else
          service_time = service_date.time.to_i
          if (service_time + service[:timeout].to_i) < Time.now.to_i
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
      classob = Service_watcher::Plugin.const_get(Php4r.ucwords(args["pluginname"]))
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
        @appserver.log("Service was successfully checked.", args["service"])
        
        if args["service"].failed?
          args["service"][:failed] = 0
          @appserver.log("Fail-marking removed.", args["service"])
        end
      else
        args["plugin"].check
      end
      
      return {
        "errorstatus" => false
      }
    rescue SystemExit, Interrupt
      raise
    rescue Exception => e
      if args["service"]
        failed = args["service"].failed?
        
        if !args["service"].failed?
          args["service"][:failed] = 1
          @appserver.log("Fail-marking set.", args["service"])
        end
        
        @appserver.log("Service threw error as it was checked.", args["service"], {
          :comment => JSON.generate(
            :error_str => Knj::Errors.error_str(e)
          )
        })
        
        #Only send reports if the service was already marked as failed.
        if !failed
          args["service"].reporters_merged.each do |reporter|
            begin
              reporter.reporter_plugin.report_error("reporter" => reporter, "error" => e, "pluginname" => args["pluginname"], "plugin" => args["plugin"], "service" => args["service"])
              @appserver.dprint "Reported error: #{Knj::Errors.error_str(e)}\n\n"
              @appserver.log("Reported an error for service '#{args["service"].name} (#{args["service"].id})' with success.", reporter, {
                :comment => JSON.generate(
                  :error_str => Knj::Errors.error_str(e)
                )
              })
            rescue => reporter_e
              @appserver.dprint "Error occurred when running reporter: #{Knj::Errors.error_str(reporter_e)}\n\n"
              @appserver.log("Reporter threw an error as it tried to report for service '#{args["service"].name} (#{args["service"].id})': '#{reporter_e.message}'.", reporter, {
                :comment => JSON.generate(
                  :error_str => Knj::Errors.error_str(e),
                  :reporter_error_str => Knj::Errors.error_str(reporter_e)
                )
              })
            end
          end
        end
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
  
  def self.parse_subject_info_args
    return [{
      :title => "%subject%",
      :type => :info,
      :value => _("Will we replaced with the error inspection of the error.")
    }]
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
  
  def join
    @appserver.join
  end
  
  def load_request
    self.parse_args(_get)
  end
  
  #Parses key-numeric-hashes into arrays and converts special model-strings into actual models.
  def parse_args(arg)
    if arg.is_a?(Hash) and Knj::ArrayExt.hash_numeric_keys?(arg)
      arr = []
      
      arg.each do |key, val|
        arr << val
      end
      
      return self.parse_args(arr)
    elsif arg.is_a?(Hash)
      arg.each do |key, val|
        arg[key] = self.parse_args(val)
      end
      
      return arg
    elsif arg.is_a?(Array)
      arg.each_index do |key|
        arg[key] = self.parse_args(arg[key])
      end
      
      return arg
    elsif arg.is_a?(String) and match = arg.match(/^#<Model::(.+?)::(\d+)>$/)
      return @ob.get(match[1], match[2])
    else
      return arg
    end
  end
end