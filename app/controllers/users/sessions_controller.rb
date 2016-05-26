class Users::SessionsController < Devise::SessionsController
  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)
    yield resource if block_given?
    location = after_sign_in_path_for(resource)
    flash[:warning] = current_user.get_announcements_by_roles_and_portal(location) if current_user.present?
    respond_with resource, location: location
  end
end
