class Service_watcher::Model::Service < Knj::Datarow
  joined_tables(
    :Option => {
      :where => {
        "object_class" => :Service,
        "object_id" => {:type => :col, :name => :id}
      }
    }
  )
  
  has_many [{
    :class => :Option,
    :method => :options,
    :where => {
      "object_class" => :Service
    },
    :col => :object_id
  }]
  
  has_one [
    :Group
  ]
  
  def self.add(d)
    raise _("No plugin was given.") if d.data[:plugin].to_s.length <= 0
    
    if d.data[:group_id].to_i > 0
      group = d.ob.get(:Group, d.data[:group_id])
    end
  end
  
  def delete
    self.options.each do |opt|
      ob.delete(opt)
    end
  end
  
  def del_details
    db.delete("services_options", {"service_id" => self["id"]})
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
    
    if self.group
      self.group.reporters.each do |link|
        if reporters.index(link.reporter) == nil
          reporters << link.reporter
        end
      end
    end
    
    return reporters
  end
  
  def plugin_class
    raise _("No plugin set for this service.") if self[:plugin].to_s.length <= 0
    return Service_watcher::Plugin.const_get(Php4r.ucwords(self[:plugin]))
  end
  
  def check
    self.plugin_class.check(self.details)
  end
  
  def client_data
    return {
      :id => id,
      :name => name,
      :plugin => self[:plugin],
      :timeout => self[:timeout],
      :group_id => self[:group_id],
      :failed => self[:failed]
    }
  end
end