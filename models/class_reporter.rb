class Service_watcher::Model::Reporter < Knj::Datarow
  joined_tables(
    :Option => {
      :where => {
        "object_class" => :Reporter,
        "object_id" => {:type => :col, :table => :Reporter, :name => :id}
      }
    }
  )
  
  has_many [{
    :class => :Option,
    :method => :options,
    :where => {
      "object_class" => :Reporter
    },
    :col => :object_id
  }]
  
  def delete
    self.groups.each do |link|
      ob.delete(link)
    end
    
    self.services.each do |link|
      ob.delete(link)
    end
    
    self.del_details
  end
  
  def del_details
    self.options.each do |opt|
      ob.delete(opt)
    end
  end
  
  def details
    data = {}
    self.options.each do |opt|
      data[opt[:key]] = opt[:value]
    end
    
    return data
  end
  
  def reporter_plugin
    raise sprintf(_("No plugin has been set for this reporter (%s)."), self.id) if self[:plugin].to_s.strip.length <= 0
    return Service_watcher::Reporter.const_get(Php4r.ucwords(self[:plugin])).new(self.details)
  end
  
  def groups(args = {})
    return ob.list(:Group_reporterlink, {"reporter" => self}.merge(args))
  end
  
  def services(args = {})
    return ob.list(:Service_reporterlink, {"reporter" => self}.merge(args))
  end
  
  def client_data
    return {
      :id => id,
      :name => name,
      :plugin => self[:plugin]
    }
  end
end