#require "knjrbfw"
require "knj/autoload"

class Service_watcher
  attr_reader :appserver, :controllers, :db, :ob, :plugins
  
  class Controllers; end
  class Plugin; end
  
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
    
    reporters_path = "#{path}/reporters"
    Dir.foreach(reporters_path) do |reporter_file|
      if reporter_file != "." and reporter_file != ".."
        autoload(("ServiceWatcherReporter" + Knj::Php.ucwords(reporter_file.slice(30..-4))).to_sym, reporters_path + "/" + reporter_file)
      end
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
      :module => Service_watcher,
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
    @appserver = Knjappserver.new(
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
    )
    
    
    #Define various variables which should be available in the various controllers.
    @appserver.define_magic_var(:_sw, self)
    @appserver.define_magic_var(:_ob, @ob)
    
    
    #Start the appserver.
    @appserver.start
  end
  
  def self.plugin_class(string)
    return Service_watcher::Plugin.const_get(Knj::Php.ucwords(string))
  end
  
  def self.check_and_report(args)
    staticmethod = false
    
    if args.is_a?(Service_watcher::Service)
      args = {
        "service" => args,
        "pluginname" => args["plugin"]
      }
    end
    
    if !args["plugin"] and args["pluginname"]
      classob = Service_watcher.plugin_class(args["pluginname"])
      if classob.respond_to?("check")
        staticmethod = true
      else
        args["plugin"] = classob.new(args["service"].details)
      end
    end
    
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
end