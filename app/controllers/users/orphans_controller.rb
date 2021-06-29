# frozen_string_literal: true

module Users
  class OrphansController < ApplicationController
    layout "two_column"
    layout "single_column", only: [:index]
    before_action :check_agent_role
    before_action :set_orphan, only: [:show, :destroy]

    def index
      @orphans = User.orphans
      respond_to do |format|
        format.html { render '/users/orphans/index.html.erb' }
      end
    end

    def show; end

    def destroy
      @orphan.destroy
      respond_to do |format|
        format.html { redirect_to exchanges_hbx_profiles_path, notice: 'Orphan user account was successfully deleted.' }
        format.json { head :no_content }
      end
    end

    private

    def check_agent_role
      redirect_to root_path, :flash => { :error => "You must be an HBX Administrator" } unless current_user.has_hbx_staff_role?
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_orphan
      @orphan = User.find(params[:id])
    end

  end
end
