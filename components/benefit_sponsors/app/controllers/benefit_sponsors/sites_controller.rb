module BenefitSponsers
  class SitesController < ApplicationController
    #before_action :find_site, only: [:show, :edit, :update, :destroy]

    def index
    end

    def new
      @site = Site.new
    end

    def create
      redirect_to action: 'index'
    end

    def edit
      @site = Site.find(params[:id]) # remove this and move to private method after writing show/edit/update/destory method. As per DRY
    end

    # private
    #
    # def find_site
    #   @site = Site.find(params[:id])
    # end
  end
end
