module BenefitSponsers
  # Sites Controller
  class SitesController < ApplicationController
    before_action :find_hbx_admin_user

    def index
    end

    def update
    end

    def destroy
    end

    private

    def find_hbx_admin_user
      fail NotAuthorizedError unless current_user.has_hbx_staff_role?
      # redirect_to root_url
    end
  end
end