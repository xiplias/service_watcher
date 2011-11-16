class Service_watcher::Model::Group < Knj::Datarow
  def self.add(d)
    raise _("No name was given.") if d.data[:name].to_s.strip.length <= 0
  end
  
  def services(args = {})
    return ob.list(:Service, {"group" => self}.merge(args))
  end
  
  def reporters(args = {})
    return ob.list(:Group_reporterlink, {"group" => self}.merge(args))
  end
  
  def name
    return self[:name]
  end
  
  def update(hash)
    hash.each do |key, val|
      raise _("Empty name was given.") if key == :name and val.to_s.strip.length <= 0
    end
    
    super(hash)
  end
  
  def client_data
    return {
      :id => id,
      :name => name
    }
  end
end