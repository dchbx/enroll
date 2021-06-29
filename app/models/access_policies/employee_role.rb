# frozen_string_literal: true

module AccessPolicies
  class EmployeeRole
    attr_accessor :user

    def initialize(user)
      @user = user
    end

    def authorize_employee_role(employee_role, controller)
      return true if user.has_hbx_staff_role? || user.has_csr_subrole? || is_broker_for_employer?(employee_role.employer_profile_id) || is_general_agency_staff_for_employer?(employee_role.employer_profile_id)
      if user.person.employee_roles.map(&:id).map(&:to_s).include? employee_role.id.to_s
        true
      else
        controller.redirect_to_check_employee_role
      end
    end

    def is_broker_for_employer?(employer_id)
      person = user.person
      return false unless person.broker_role || person.broker_agency_staff_roles.present?
      if person.broker_role
        employers = ::EmployerProfile.find_by_writing_agent(person.broker_role)
      else
        broker_agency_profiles = person.broker_agency_staff_roles.map {|role| ::BrokerAgencyProfile.find(role.broker_agency_profile_id) }
        employers = broker_agency_profiles.map { |bap| ::EmployerProfile.find_by_broker_agency_profile(bap) }.flatten
      end
      employers.map(&:id).map(&:to_s).include?(employer_id.to_s)
    end

    def is_general_agency_staff_for_employer?(employer_id)
      person = user.person
      if person.general_agency_staff_roles.present?
        begin
          person.general_agency_staff_roles.last.general_agency_profile.employer_clients.map(&:_id).include?(employer_id)
        rescue StandardError
          false
        end
      else
        false
      end
    end
  end
end
