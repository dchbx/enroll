module BenefitSponsors
  module Organizations
    module OrganizationForms
      class StaffRoleFormPolicy < ApplicationPolicy

        attr_reader :service

        def initialize(user, record)
          super
          @service = BenefitSponsors::Services::StaffRoleService.new(
              profile_id: record.profile_id
          )
        end

        def create?
          return true if admin?
          return true if can_edit?
        end

        def edit?
          return true if admin?
          return true if can_edit?
        end

        def destroy?
          return true if admin?
          return true if can_edit?
        end

        def approve?
          return true if admin?
          return true if can_edit?
        end

        def admin?
          user.has_hbx_staff_role? && user.person && user.person.hbx_staff_role.permission.modify_employer
        end

        def profile
          service.find_profile(record)
        end

        def can_edit?
          reg_service = Services::NewProfileRegistrationService.new(profile_id: record.profile_id)
          return true if (reg_service.is_broker_for_employer?(user, record) || reg_service.is_general_agency_staff_for_employer?(user, record))
          return true if Person.staff_for_employer(profile).include?(user.person)
        end

      end
    end
  end
end
