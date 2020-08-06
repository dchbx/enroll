# frozen_string_literal: true

class CustomFailureApp < Devise::FailureApp
  include Config::SiteConcern

  def redirect
    message = warden.message || warden_options[:message]
    if message == :timeout
      redirect_to(site_redirect_on_timeout_route.to_s) && return
    else
      super
    end
  end
end
