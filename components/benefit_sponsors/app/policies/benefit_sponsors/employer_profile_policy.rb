module BenefitSponsors
  class EmployerProfilePolicy < ApplicationPolicy

    def show?
      return false unless user.present?
      user.has_hbx_staff_role? || is_broker_for_employer?(record) || is_general_agency_staff_for_employer?(record) || is_broker_staff_role_for_employer?(record) || is_staff_role_for_employer?(record)
    end

    def show_pending?
      return false unless user.present?
      true
    end

    def coverage_reports?
      return false unless user.present?
      return true if (user.has_hbx_staff_role? && can_list_enrollments?) || is_broker_for_employer?(record) || is_general_agency_staff_for_employer?(record) || is_broker_staff_role_for_employer?(record)
      is_staff_role_for_employer?(record)
    end

    def export_census_employees?
      show?
    end

    def inbox?
      show?
    end

    def is_staff_role_for_employer?(profile)
      active_staff_roles = user.person.employer_staff_roles.active
      active_staff_roles.any? {|role| role.benefit_sponsor_employer_profile_id == record.id }
    end

    def is_broker_staff_role_for_employer?(profile)
      staff_roles = user.person.broker_agency_staff_roles
      broker_profiles = staff_roles.map(&:benefit_sponsors_broker_agency_profile_id)
      profile.broker_agency_accounts.any? {|acc|  broker_profiles.include?(acc.benefit_sponsors_broker_agency_profile_id)}
    end

    def is_broker_for_employer?(profile)
      broker_role = user.person.broker_role
      return false unless broker_role
      profile.broker_agency_accounts.any? {|acc| acc.writing_agent_id == broker_role.id}
    end

    def is_general_agency_staff_for_employer?(profile)
      staff_roles = user.person.active_general_agency_staff_roles
      if staff_roles
        ga_profiles = staff_roles.map(&:benefit_sponsors_general_agency_profile_id)
        return false if profile.general_agency_accounts.blank?
        profile.general_agency_accounts.any? {|acc|  ga_profiles.include?(acc.benefit_sponsrship_general_agency_profile_id)}
      else
        false
      end
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
      user.has_hbx_staff_role? && user.person.hbx_staff_role.permission.modify_employer
    end

    def can_add_staff_roles?
      user.person.hbx_staff_role.permission.can_add_staff_roles
    end

    def list_staff_roles?
      return false if user.blank?
      return true if  (user.has_hbx_staff_role? && can_add_staff_roles?) || is_broker_for_employer?(record) || is_general_agency_staff_for_employer?(record)
      is_staff_role_for_employer?(record)
    end
  end
end
