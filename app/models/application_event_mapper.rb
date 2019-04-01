class ApplicationEventMapper
  Resource = Struct.new(:resource_name, :identifier_method, :identifier_key, :search_method)
  ResourceReverseLookup = Struct.new(:mapped_class, :identifier_key, :search_method)

  EVENT_PREFIX = "acapi.info.events."

  EVENT_MAP = {
      employer: {
          binder_paid: :benefit_coverage_initial_binder_paid,        
        }
    }

  RESOURCE_MAP = {
    "EmployerProfile" => Resource.new(:employer, :hbx_id, :employer_id, :by_hbx_id),
    "ConsumerRole" => Resource.new(:consumer_role, :id, :consumer_role_id, :find),
    "EmployeeRole" => Resource.new(:employee, :id, :employee_role_id, :find),
    "CensusEmployee" => Resource.new(:census_employee, :id, :census_employee_id, :find)
  }

  REVERSE_LOOKUP_MAP = RESOURCE_MAP.inject({}) do |acc, vals|
    key, mapping = vals
    acc[mapping.resource_name.to_s] = ResourceReverseLookup.new(key.constantize, mapping.identifier_key.to_s, mapping.search_method)
    acc
  end

  class << self

    def extract_event_parts(event_name)
      event_parts = event_name.split(".")
      [event_parts[3], event_parts[4]]
    end

    def lookup_resource_mapping(event_name)
      resource_name, *garbage_i_dont_care_about = extract_event_parts(event_name)
      return REVERSE_LOOKUP_MAP[resource_name] if REVERSE_LOOKUP_MAP.has_key?(resource_name)
      ResourceReverseLookup.new(resource_name.camelize.constantize, "#{resource_name}_id", :find) rescue nil
    end

    def map_resource(resource_name)
      return RESOURCE_MAP[resource_name.to_s] if RESOURCE_MAP.has_key?(resource_name.to_s)
      mapped_name = resource_name.to_s.underscore.to_sym
      Resource.new(mapped_name, :id, (mapped_name.to_s + "_id").to_sym, :find)
    end

    def map_event_name(resource_mapping, transition_event_name)
      event_name = transition_event_name.to_s.sub(/\!$/, '').to_sym
      resource_prefix = EVENT_PREFIX + "#{resource_mapping.resource_name}."
      if EVENT_MAP[resource_mapping.resource_name] && EVENT_MAP[resource_mapping.resource_name][event_name]
        event_name = EVENT_MAP[resource_mapping.resource_name][event_name]
      end
      resource_prefix + event_name.to_s
    end
  end
end