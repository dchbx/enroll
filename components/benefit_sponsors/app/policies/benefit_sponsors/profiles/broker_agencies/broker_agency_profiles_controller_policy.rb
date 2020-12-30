module BenefitSponsors
  module Profiles
    module BrokerAgencies
      class BrokerAgencyProfilesControllerPolicy < ApplicationPolicy

        def family_index?
          user.has_hbx_staff_role? || user.has_broker_role? || user.has_broker_agency_staff_role?
        end

        def family_datatable?
          family_index?
        end

        def index?
          return user.has_hbx_staff_role? || user.has_csr_role?
        end

        def show?
          self.send(:index?)
        end

        def redirect_signup?
          return false if user.blank?
          self.send(:family_index?)
        end

        def staff_index?
          user.has_hbx_staff_role? || user.has_csr_role? || user.has_consumer_role?
        end
      end
    end
  end
end
