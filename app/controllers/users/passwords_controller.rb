class Users::PasswordsController < Devise::PasswordsController
  before_filter :confirm_identity, only: [:create]
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?
    if successfully_sent?(resource)
      resource.security_question_responses.destroy_all

      respond_to do |format|
       format.html { respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name)) }
       format.js
      end

    else
      respond_with(resource)
    end
  end

  private

  def user
    @user ||= User.find_by(email: params[:user][:email])
  end

  def confirm_identity
    if current_user && current_user.has_role?('hbx_staff')
      return true
    end

    unless user.identity_confirmed_token == params[:user][:identity_confirmed_token]
      flash[:error] = "Something went wrong, please try again"
      redirect_to new_user_password_path
      return false
    end
  end

  protected

  def after_resetting_password_path_for(resource_name)
    root_url
  end
end
