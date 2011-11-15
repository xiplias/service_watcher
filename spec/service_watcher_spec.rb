require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ServiceWatcher" do
  it "should require all its requirements" do
    require "rubygems"
    require "service_watcher"
    require "knjdbrevision"
    require "knjappserver"
    require "mail"
    require "knjrbfw"
    require "knj/autoload"
    
    #require "/home/kaspernj/Dev/Ruby/knjrbfw/lib/knjrbfw.rb"
    #$:.delete("/home/kaspernj/.rvm/gems/ruby-1.9.2-head/gems/knjrbfw-0.0.8/lib")
    #require "/home/kaspernj/Dev/Ruby/knjrbfw/lib/knj/autoload"
    #require "/home/kaspernj/Dev/Ruby/knjrbfw/lib/knj/datarow"
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
      :db => @db_sample,
      :knjappserver_args => {
        :knjrbfw_path => "/home/kaspernj/Dev/Ruby/knjrbfw/lib/"
      }
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
    
    $reporter = $client.request(
      :c => :reporter,
      :a => :add,
      :name => "TestReporter",
      :plugin => :email,
      :options => JSON.parse(File.read("#{File.dirname(__FILE__)}/service_watcher_spec_smtp.json"))
    )
    $group = $client.request(
      :c => :group,
      :a => :add,
      :name => "TestReporterGroup"
    )
    $reporter_link = $client.request(
      :c => :group,
      :a => :add_reporter,
      :group_id => $group["group_id"],
      :reporter_id => $reporter["reporter_id"]
    )
    $service = $client.request(
      :c => :service,
      :a => :add,
      :name => "TestMailSMTPSuccess",
      :plugin => "mail",
      :timeout => 5,
      :group_id => $group["group_id"],
      :options => {
        "txthost" => "smtp.kaspernj.org",
        "txtport" => 465,
        "seltype" => "IMAP",
        "chessl" => 1
      }
    )
    $service_fail = $client.request(
      :c => :service,
      :a => :add,
      :name => "TestMailSMTPFail",
      :plugin => "mail",
      :timeout => 5,
      :group_id => $group["group_id"],
      :options => {
        "txthost" => "asdklajdhadauksdhajkdh",
        "txtport" => 12311,
        "seltype" => "IMAP",
        "chessl" => 0
      }
    )
    
    #Check the service.
    $client.request(:c => :service, :a => :check, :service_id => $service["service_id"])
    
    services_list = $client.request(:c => :service, :a => :list)
    raise "Service-list should contain two items." if services_list.length != 2
    
    plugins_list = $client.request(:c => :plugin, :a => :list)
    
    #Get arguments for all plugins.
    plugins_list.each do |plugin_name, plugin_data|
      args = $client.request(:c => :plugin, :a => :args, :plugin_name => plugin_name)
    end
    
    reporters = $client.request(:c => :reporter, :a => :list)
    reporters.each do |reporter_name, reporter_data|
      args = $client.request(:c => :reporter, :a => :args, :reporter_name => reporter_name)
    end
  end
  
  it "should run the added service automatically and set date-lastrun on it." do
    service = $sw.ob.get_by(:Service)
    
    Timeout.timeout(2) do
      loop do
        all_ran = true
        $sw.ob.list(:Service) do |service|
          all_ran = false if !service.date_lastrun
        end
        
        break if all_ran
        sleep 0.5
      end
    end
  end
  
  it "should be able to stop" do
    $sw.stop
  end
end
