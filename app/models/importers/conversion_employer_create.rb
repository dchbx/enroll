module Importers
  class ConversionEmployerCreate < ConversionEmployer

    def initialize(opts = {})
      super(opts)
    end
  
    def save
      return false unless valid?

      new_organization = Organization.where(:fein => fein).first

      puts "Processing Add ---#{legal_name}"  unless Rails.env.test?
      if new_organization
        new_organization.create_employer_profile({
          :broker_agency_accounts => assign_brokers,
          :general_agency_accounts => assign_general_agencies,
          :entity_kind => "c_corporation",
          :profile_source => "conversion",
          :registered_on => registered_on
        })
      else
        new_organization = Organization.new({
          :fein => fein,
          :legal_name => legal_name,
          :dba => dba,
          :office_locations => map_office_locations,
          :employer_profile => EmployerProfile.new({
            :broker_agency_accounts => assign_brokers,
            :general_agency_accounts => assign_general_agencies,
            :entity_kind => "c_corporation",
            :profile_source => "conversion",
            :registered_on => registered_on
          })
        })
      end
      save_result = new_organization.save
      if save_result
        emp = new_organization.employer_profile
        map_poc(emp)
      end
      propagate_errors(new_organization)
      return save_result
    end
  end
end
