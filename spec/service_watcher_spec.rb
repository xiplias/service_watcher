require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ServiceWatcher" do
  it "should require all its requirements" do
    require "rubygems"
    require "service_watcher"
    require "knjrbfw"
    require "knjdbrevision"
    require "knjappserver"
    require "knj/autoload"
  end
  
  it "should be able to generate a sample database from database schema" do
    begin
      dbschemapath = "#{File.dirname(__FILE__)}/../files/database_schema.rb"
      raise "'#{dbschemapath}' did not exist." if !File.exists?(dbschemapath)
      require dbschemapath
      raise "No schema-variable was spawned." if !$schema
      
      dbpath = "#{File.dirname(__FILE__)}/../files/database.sqlite3"
      
      @db_sample = Knj::Db.new(
        :type => "sqlite3",
        :path => dbpath,
        :return_keys => "symbols"
      )
      
      dbrev = Knjdbrevision.new
      dbrev.check_db($schema, @db_sample)
    rescue => e
      puts e.inspect
      puts e.backtrace
      raise e
    end
  end
  
  it "should start a webserver for JSON access" do
    begin
      dbpath = "#{File.dirname(__FILE__)}/../files/database.sqlite3"
      sw = Service_watcher.new(
        :port => 1515,
        :db_args => {
          :type => "sqlite3",
          :path => dbpath,
          :return_keys => "symbols"
        }
      )
    rescue => e
      puts e.inspect
      puts e.backtrace
      raise e
    end
    
    http = Knj::Http.new("host" => "localhost", "port" => 1515)
    ret = http.get("/")
  end
end
