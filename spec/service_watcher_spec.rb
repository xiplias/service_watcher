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
  
  it "should start a webserver for JSON access" do
    dbpath = "#{File.dirname(__FILE__)}/../files/database.sqlite3"
    File.unlink(dbpath) if File.exists?(dbpath)
    
    @db_sample = Knj::Db.new(
      :type => "sqlite3",
      :path => dbpath,
      :return_keys => "symbols",
      :index_append_table_name => true
    )
    
    $sw = Service_watcher.new(
      :port => 1515,
      :db => @db_sample
    )
    
    user = $sw.ob.add(:User, {
      :username => "Testuser",
      :password => Digest::MD5.hexdigest("123")
    })
    
    $client = Service_watcher::Client.new(
      :host => "localhost",
      :port => 1515
    )
    $client.login(:username => "Testuser", :password => "123")
    
    $client.request(:c => :service, :a => :add, :name => "Testservice")
    
    services_list = $client.request(:c => :service, :a => :list)
    raise "Service-list should contain one item." if services_list.length != 1
    
    plugins_list = $client.request(:c => :plugin, :a => :list)
    
    #Get arguments for all plugins.
    plugins_list.each do |plugin_name, plugin_data|
      args = $client.request(:c => :plugin, :a => :args, :plugin_name => plugin_name)
    end
  end
  
  it "should be able to test the mail plugin." do
    service = $client.request(:c => :service, :a => :add, :name => "TestMailSMTP", :plugin => "mail", :options => {
      "txthost" => "smtp.kaspernj.org",
      "txtport" => 465,
      "seltype" => "IMAP",
      "chessl" => 1
    })
    
    $client.request(:c => :service, :a => :check, :service_id => service["service_id"])
  end
end
