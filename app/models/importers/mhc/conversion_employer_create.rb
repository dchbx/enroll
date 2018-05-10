module Importers::Mhc
  class ConversionEmployerCreate < ConversionEmployer

    def initialize(opts = {})
      super(opts)
    end

    def save
      if valid?
        new_organization = Organization.where(:fein => fein).first
        puts "Processing Add ---#{legal_name}" unless Rails.env.test?

        if new_organization
          new_organization.create_employer_profile(employer_attributes)
        else
          new_organization = Organization.new({
            :fein => fein,
            :legal_name => legal_name,
            :dba => dba,
            :office_locations => map_office_locations,
            :employer_profile => EmployerProfile.new(employer_attributes),
            :issuer_assigned_id => assigned_employer_id
            })
        end

        save_result = new_organization.save
        if save_result
          emp = new_organization.employer_profile
          approve_attestation(emp) if emp.employer_attestation.blank?
          map_poc(emp)
        end

        propagate_errors(new_organization)
        return save_result
      end
    end

    def approve_attestation(employer)
      attestation = employer.build_employer_attestation
      attestation.submit
      attestation.approve
      attestation.save
    end

    # TODO: Issuer Assigned Employer ID (should be assigned)

    def employer_attributes
      {
        :broker_agency_accounts => assign_brokers,
        :general_agency_accounts => assign_general_agencies,
        :entity_kind => "c_corporation",
        :profile_source => "conversion",
        :sic_code => sic_code,
        :registered_on => registered_on
      }
    end
  end
end
