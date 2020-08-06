# frozen_string_literal: true

class ExternalApplicationsController < ApplicationController

  # Here we:
  # - Look up the external application,
  # - Check permissions for the current user
  # - Set the JWT in Local Storage
  # - Re-direct to the external API
  def show
    external_application = ExternalApplications::ApplicationProfile.find_by_application_name(params[:id])
    if external_application
      authorize external_application, :visit?
      @url = external_application.url
      @jwt = current_user.generate_jwt(warden.config[:default_scope], nil)
    else
      render status: 404, nothing: true
    end
  end
end