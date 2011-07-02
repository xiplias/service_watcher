require "knjrbfw"
require "knj/autoload"

class Service_watcher
  plugins_path = "#{File.dirname(__FILE__)}/../plugins"
  Dir.new(plugins_path).entries.each do |plugin_file|
    if (plugin_file != "." and plugin_file != "..")
        autoload(("ServiceWatcherPlugin" + Knj::Php.ucwords(plugin_file.slice(28..-4))).to_sym, plugins_path + "/" + plugin_file)
    end
  end

  reporters_path = "#{File.dirname(__FILE__)}/../reporters"
  Dir.new(reporters_path).entries.each do |reporter_file|
    if (reporter_file != "." and reporter_file != "..")
        autoload(("ServiceWatcherReporter" + Knj::Php.ucwords(reporter_file.slice(30..-4))).to_sym, reporters_path + "/" + reporter_file)
    end
  end
  
  def initialize(args = {})
    #Make arguments array and merge with the given arguments.
    @args = {
      :port => 80,
      :host => "0.0.0.0"
    }.merge(args)
    
    @db = Knj::Db.new(@args[:db_args])
    @ob = Knj::Objects.new(
      :db => @db,
      :class_path => "#{File.dirname(__FILE__)}/../models",
      :module => Service_watcher
    )
    
    @erbhandler = Knjappserver::ERBHandler.new
    @appserver = Knjappserver.new(
        :debug => false,
        :autorestart => false,
        :verbose => false,
        :title => "Service_watcher",
        :port => @args[:port],
        :host => @args[:host],
        :default_page => "index.rhtml",
        :doc_root => "#{File.dirname(__FILE__)}/../json_pages",
        :hostname => false,
        :default_filetype => "text/html",
        :engine_webrick => true,
        :error_report_emails => [@args[:admin_email]],
        :error_report_from => @args[:admin_email],
        :locales_root => "#{File.dirname(__FILE__)}/../locales",
        :max_requests_working => 5,
        :filetypes => {
          :jpg => "image/jpeg",
          :gif => "image/gif",
          :png => "image/png",
          :html => "text/html",
          :htm => "text/html",
          :rhtml => "text/html",
          :css => "text/css",
          :xml => "text/xml",
          :js => "text/javascript"
        },
        :handlers => [
          :file_ext => "rhtml",
          :callback => @erbhandler.method(:erb_handler)
        ],
        :db => @db,
        :smtp_args => @args[:smtp]
    )
    @appserver.update_db
    @appserver.start
  end
  
  def self.plugin_class(string)
    object_name = "ServiceWatcherPlugin" + Knj::Php.ucwords(string)
    return Kernel.const_get(object_name)
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