class Service_watcher::Service < Knj::Datarow
  joined_tables(
    :Option => {
      :where => {
        "object_class" => "Service",
        "object_id" => {:type => :col, :name => :id}
      }
    }
  )
  
  has_many [{
    :class => :Option,
    :method => :options,
    :where => {
      "object_class" => "Service",
      "object_id" => {:type => :col, :table => :Service, :name => :id}
    },
    :col => :object_id
  }]
  
  has_one [
    :Group
  ]
  
  def delete
    self.del_details
  end
  
  def del_details
    db.delete("services_options", {"service_id" => self["id"]})
  end
  
  def add_detail(name, data)
    db.insert("services_options", {
      "service_id" => self["id"],
      "opt_name" => name,
      "opt_value" => data
    })
  end
  
  def details
    data = {}
    self.options.each do |option|
      data[option[:key]] = option[:value]
    end
    
    return data
  end
  
  def reporters
    return ob.list(:Service_reporterlink, {"service" => self})
  end
  
  def reporters_merged
    reporters = []
    self.reporters.each do |link|
      reporters << link.reporter
    end
    
    group.reporters.each do |link|
      if !reporters.index(link.reporter)
        reporters << link.reporter
      end
    end
    
    return reporters
  end
  
  def plugin_class
    raise _("No plugin set for this service.") if self[:plugin].to_s.length <= 0
    return Service_watcher::Plugin.const_get(Knj::Php.ucwords(self[:plugin]))
  end
  
  def check
    self.plugin_class.check(self.details)
  end
end