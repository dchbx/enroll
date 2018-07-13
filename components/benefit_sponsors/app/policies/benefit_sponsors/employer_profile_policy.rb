module BenefitSponsors
  class EmployerProfilePolicy < ApplicationPolicy

    def show?
      return false unless user.present?
      return true if user.has_hbx_staff_role? || is_broker_for_employer?(record) || is_general_agency_staff_for_employer?(record)
      is_staff_role_for_employer?(record)
    end

    def show_pending?
      return false unless user.present?
      true
    end

    def coverage_reports?
      return false unless user.present?
      return true if (user.has_hbx_staff_role? && can_list_enrollments?) || is_broker_for_employer?(record) || is_general_agency_staff_for_employer?(record)
      is_staff_role_for_employer?(record)
    end

    def export_census_employees?
      show?
    end

    def inbox?
      show?
    end

    def is_staff_role_for_employer?(profile)
      staff_roles = user.person.employer_staff_roles
      staff_roles.any? {|role| role.benefit_sponsor_employer_profile_id == record.id }
    end

    def is_broker_for_employer?(profile)
      broker_role = user.person.broker_role
      return false unless broker_role
      profile.broker_agency_accounts.any? {|acc| acc.writing_agent_id == broker_role.id}
    end

    def is_general_agency_staff_for_employer?(profile)
      # TODO
      return false
    end

    def updateable?
      return false if (user.blank? || user.person.blank?)
      return true if  (user.has_hbx_staff_role? && can_modify_employer?) || is_broker_for_employer?(record) || is_general_agency_staff_for_employer?(record)
      is_staff_role_for_employer?(record)
    end

    def list_enrollments?
      coverage_reports?
    end

    def can_list_enrollments?
      user.person.hbx_staff_role.permission.list_enrollments
    end

    def can_modify_employer?
      user.person.hbx_staff_role.permission.modify_employer
    end
  end
end
