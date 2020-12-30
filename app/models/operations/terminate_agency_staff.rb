module Operations
  class TerminateAgencyStaff

    def initialize(person_id, role_id)
      @person_id = person_id
      @role_id = role_id
    end

    def call
      begin
        person = Person.find(@person_id)
        role = person.broker_agency_staff_roles.select{ |role| role._id.to_s == @role_id }.first ||
                 person.general_agency_staff_roles.select{ |role| role._id.to_s == @role_id }.first
        return :no_role_found unless role
        role.class.name == "BrokerAgencyStaffRole" ? role.broker_agency_terminate! : role.general_agency_terminate!
        :ok
      rescue Mongoid::Errors::DocumentNotFound
        :person_not_found
      rescue
        :error
      end
    end

    def policy_class
      AngularAdminApplicationPolicy
    end
  end
end