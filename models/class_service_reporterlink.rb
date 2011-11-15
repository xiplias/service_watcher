class Service_watcher::Model::Service_reporterlink < Knj::Datarow
  has_one [
    :Reporter,
    :Service
  ]
  
  def self.add(d)
    service = d.ob.get(:Service, data[:service_id])
    reporter = d.ob.get(:Reporter, data[:reporter_id])
    
    link = d.ob.list(:Service_reporterlink, {"service" => service, "reporter" => reporter})
    if link.length > 0
      raise Knj::Errors::Notice, _("Such a reporter is already added for that service.")
    end
  end
end