# frozen_string_literal: true

module BenefitSponsors
  module Profiles
    module GeneralAgencies
      class GeneralAgencyProfilesControllerPolicy < ApplicationPolicy

        def families?
          user.has_hbx_staff_role? || user.has_general_agency_staff_role?
        end

        # def family_datatable?
        #   family_index?
        # end

        # def index?
        #   return user.has_hbx_staff_role? || user.has_csr_role?
        # end

        def employers?
          show?
        end

        def show?
          return false if user.blank?
          user.has_hbx_staff_role? || user.has_general_agency_staff_role?
        end

        def edit_staff?
          show?
        end

        def update_staff?
          show?
        end

        def staffs?
          show?
        end

        def redirect_signup?
          user.present?
        end

        def staff_index?
          show?
        end
      end
    end
  end
end
