module BenefitSponsors
  module Profiles
    module BrokerAgencies
      class BrokerAgencyProfilesControllerPolicy < ApplicationPolicy

        def family_index?
          return user.has_hbx_staff_role? || user.has_broker_role?
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
          user.present?
        end

        def staff_index?
          self.send(:index?)
        end
      end
    end
  end
end
