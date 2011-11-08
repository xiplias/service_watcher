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
    dbschemapath = "#{File.dirname(__FILE__)}/../files/database_schema.rb"
    raise "'#{dbschemapath}' did not exist." if !File.exists?(dbschemapath)
    require dbschemapath
    raise "No schema-variable was spawned." if !$schema
    
    dbpath = "#{File.dirname(__FILE__)}/../files/database.sqlite3"
    File.unlink(dbpath) if File.exists?(dbpath)
    
    @db_sample = Knj::Db.new(
      :type => "sqlite3",
      :path => dbpath,
      :return_keys => "symbols",
      :index_append_table_name => true
    )
    dbrev = Knjdbrevision.new
    dbrev.init_db($schema, @db_sample)
  end
  
  it "should start a webserver for JSON access" do
    dbpath = "#{File.dirname(__FILE__)}/../files/database.sqlite3"
    sw = Service_watcher.new(
      :port => 1515,
      :db_args => {
        :type => "sqlite3",
        :path => dbpath,
        :return_keys => "symbols"
      }
    )
    
    user = sw.ob.add(:User, {
      :username => "Testuser",
      :password => Digest::MD5.hexdigest("123")
    })
    
    client = Service_watcher::Client.new(
      :host => "localhost",
      :port => 1515
    )
    client.login(:username => "Testuser", :password => "123")
    
    service = client.request(:c => :service, :a => :add, :name => "Testservice")
    
    services_list = client.request(:c => :service, :a => :list)
    raise "Service-list should contain one item." if services_list.length != 1
    
    plugins_list = client.request(:c => :plugin, :a => :list)
    Knj::Php.print_r(plugins_list)
  end
end
