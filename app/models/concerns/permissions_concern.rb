module PermissionsConcern
  extend ActiveSupport::Concern

  included do
    has_one :person
    accepts_nested_attributes_for :person, :allow_destroy => true

    # after_initialize :instantiate_person
    #  after_create :send_welcome_email

    delegate :primary_family, to: :person, allow_nil: true

    def person_id
      return nil unless person.present?
      person.id
    end

    def instantiate_person
      self.person = Person.new
    end

    def has_role?(role_sym)
      return false if person_id.blank?
      roles.any? { |r| r == role_sym.to_s }
    end

    def has_employee_role?
      person && person.active_employee_roles.present?
    end

    def has_consumer_role?
      person && person.consumer_role
    end

    def has_resident_role?
      person && person.resident_role
    end

    def has_employer_staff_role?
      person && person.has_active_employer_staff_role?
    end

    def has_broker_agency_staff_role?
      has_role?(:broker_agency_staff)
    end

    def has_general_agency_staff_role?
      has_role?(:general_agency_staff)
    end

    def has_insured_role?
      has_employee_role? || has_consumer_role?
    end

    def has_broker_role?
      has_role?(:broker)
    end

    def has_hbx_staff_role?
      has_role?(:hbx_staff) || self.try(:person).try(:hbx_staff_role)
    end

    def has_csr_role?
      has_role?(:csr)
    end

    def has_csr_subrole?
      person && person.csr_role && !person.csr_role.cac
    end

    def has_cac_subrole?
      person && person.csr_role && person.csr_role.cac
    end

    def has_assister_role?
      has_role?(:assister)
    end

    def has_agent_role?
      has_role?(:csr) || has_role?(:assister)
    end

    def can_change_broker?
      if has_employer_staff_role? || has_hbx_staff_role?
        true
      elsif has_general_agency_staff_role? || has_broker_role? || has_broker_agency_staff_role?
        false
      end
    end
  end

  class_methods do
    ROLES = {
      employee: "employee",
      resident: "resident",
      consumer: "consumer",
      broker: "broker",
      system_service: "system_service",
      web_service: "web_service",
      hbx_staff: "hbx_staff",
      employer_staff: "employer_staff",
      broker_agency_staff: "broker_agency_staff",
      general_agency_staff: "general_agency_staff",
      assister: 'assister',
      csr: 'csr',
    }
  end
end
