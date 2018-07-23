class Users::SessionsController < Devise::SessionsController
  include RecaptchaConcern if Settings.aca.recaptcha_enabled

  after_filter :log_failed_login, :only => :new

  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)
    yield resource if block_given?
    location = after_sign_in_path_for(resource)
    flash[:warning] = current_user.get_announcements_by_roles_and_portal(location) if current_user.present?
    respond_with resource, location: location
  end

  private

  def log_failed_login
    return unless failed_login?
    attempted_user = User.where(email: request.filtered_parameters["user"]["login"])
    if attempted_user.present?
      SessionIdHistory.create(session_user_id: attempted_user.first.id, sign_in_outcome: "Failed", ip_address: request.remote_ip)
    end
  end

  def failed_login?
   (options = env["warden.options"]) && options[:action] == "unauthenticated"
  end
end
