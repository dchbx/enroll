# frozen_string_literal: true

module AccessPolicies
  class GeneralAgencyProfile
    attr_accessor :user

    def initialize(user)
      @user = user
    end

    def authorize_new(controller)
      general_agency_profile_id = begin
        user.person.general_agency_staff_roles.last.general_agency_profile_id
      rescue StandardError
        nil
      end
      controller.redirect_to_show(general_agency_profile_id) if user.has_general_agency_staff_role? && general_agency_profile_id.present?
    end

    def authorize_index(controller)
      return true if user.has_hbx_staff_role? || user.has_csr_role? || user.has_broker_role?

      general_agency_profile_id = begin
        user.person.general_agency_staff_roles.last.general_agency_profile_id
      rescue StandardError
        nil
      end
      if user.has_general_agency_staff_role? && general_agency_profile_id.present?
        controller.redirect_to_show(general_agency_profile_id)
      else
        controller.redirect_to_new
      end
    end

    def authorize_assign(controller, broker_agency_profile)
      return true if user.has_broker_role? || user.has_hbx_staff_role?

      controller.redirect_to_show(broker_agency_profile.id)
    end

    def authorize_set_default_ga(controller, broker_agency_profile)
      return true if user.has_hbx_staff_role? || user.has_broker_role?

      controller.redirect_to_show(broker_agency_profile.id)
    end
  end
end
