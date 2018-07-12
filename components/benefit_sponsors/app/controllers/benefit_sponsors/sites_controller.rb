module BenefitSponsors
  # Sites Controller
  class SitesController < ApplicationController
    layout 'benefit_sponsors/application'

    def index
      @sites = BenefitSponsors::Site.all
    end

    def new
      @site = BenefitSponsors::Forms::Site.for_new
    end

    def create
      # pundit can I do this here
      @site = BenefitSponsors::Forms::Site.for_create params[:site]

      if @site.save
        redirect_to sites_path
      else
        render 'new'
      end
    end

    def edit
      @site = BenefitSponsors::Forms::Site.for_edit params[:id]
    end

    def update
      @site = BenefitSponsors::Forms::Site.for_update params[:id]

      if @site.update_attributes params[:site]
        redirect_to sites_path
      else
        render 'edit'
      end
    end

    def destroy
      @site = BenefitSponsors::Site.find params[:id]
      @site.owner_organization.destroy
      @site.destroy

      redirect_to sites_path
    end

    private

    def find_hbx_admin_user
      fail NotAuthorizedError unless current_user.has_hbx_staff_role?
      # redirect_to root_url
    end
  end
end
