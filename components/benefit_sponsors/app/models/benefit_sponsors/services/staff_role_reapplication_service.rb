# frozen_string_literal: true

# This serive will be used to resubmit staff role applications
# Staff Role can be of BrokerAgencyStaffRole, BrokerRole, Employer POC, GeneralAgencyStaffRole

module BenefitSponsors
  module Services
    class StaffRoleReapplicationService

      attr_accessor :profile_id, :person_id, :profile_type, :person

      def initialize(attrs = {})
        @profile_id = attrs[:profile_id]
        @person_id = attrs[:person_id]
        @profile_type = fetch_profile_type
        @person = fetch_person(attrs[:person_id])
      end

      def fetch_profile_type
        type = profile.class.to_s
        if type.match(/EmployerProfile/)
          'benefit_sponsor'
        elsif type.match(/BrokerAgencyProfile/)
          'broker_agency'
        elsif type.match(/GeneralAgencyProfile/)
          'general_agency'
        end
      end

      def profile
        organization = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => BSON::ObjectId.from_string(profile_id)).first
        organization.profiles.where(id: profile_id).first
      end

      def fetch_broker_role
        person.broker_role
      end

      def fetch_ga_role
        person.general_agency_staff_roles.where(benefit_sponsors_general_agency_profile_id: profile_id).first
      end

      def fetch_person(person_id)
        Person.find(person_id)
      end

      def re_apply
        status = false
        case profile_type
        when 'broker_agency'
          broker_role = fetch_broker_role
          status = broker_role.extend_application! if broker_role.may_extend_application?
          [status, broker_role]
          # person.broker_agency_staff_roles.where(benefit_sponsors_broker_agency_profile_id: profile_id).first
        when 'general_agency'
          ga_role = fetch_ga_role
          # Replace this with extend application event if introduced in future
          status = ga_role.reapply! if ga_role.may_reapply?
          [status, ga_role]
        end
      end
    end
  end
end
