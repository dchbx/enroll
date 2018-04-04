module BenefitSponsors
  # Sites Controller
  class SitesController < ApplicationController
    before_action :find_hbx_admin_user

    def index
      @sites = BenefitSponsors::Site.all
    end

    def new
      @site = BenefitSponsors::Site.new
    end

    def create
      @site = BenefitSponsors::Site.new params[:site]

      if @site.save
        redirect_to :index
      else
        render 'new'
      end
    end

    def edit
      @site = BenefitSponsors::Site.find params[:id]
    end

    def update
      @site = BenefitSponsors::Site.find params[:id]

      if @site.update_attributes params[:site]
        redirect_to :index
      else
        render 'edit'
      end
    end

    def destroy
      @site = BenefitSponsors::Site.find params[:id]
      @site.destroy

      redirect_to 'index'
    end

    private

    def find_hbx_admin_user
      fail NotAuthorizedError unless current_user.has_hbx_staff_role?
      # redirect_to root_url
    end
  end
end
