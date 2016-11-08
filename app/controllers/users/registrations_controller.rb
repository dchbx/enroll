class Users::RegistrationsController < Devise::RegistrationsController
before_filter :configure_sign_up_params, only: [:create]
# before_filter :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    build_resource(sign_up_params)
#   Check for curam user email, if present then restrict the user.
    if CuramUser.match_unique_login(resource.oim_id).first.present?
      flash[:alert] = "An account with this username ( #{params[:user][:oim_id]} ) already exists. #{view_context.link_to('Click here', SamlInformation.account_recovery_url)} if you've forgotten your password."
      render :new and return
    end

    if resource.email.strip.present? && CuramUser.match_unique_login(resource.email.strip).first.present? 
      flash[:alert] = "An account with this email ( #{params[:user][:email]} ) already exists. #{view_context.link_to('Click here', SamlInformation.account_recovery_url)} if you've forgotten your password."
      render :new and return
    end

    headless = User.where(email: /^#{Regexp.quote(resource.email)}$/i).first

    if headless.present? && !headless.person.present?
      headless.destroy
    end
    
    resource.email = resource.oim_id if resource.email.blank? && resource.oim_id =~ Devise.email_regexp

    headless = User.where(oim_id: /^#{Regexp.quote(resource.oim_id)}$/i).first

    if headless.present? && !headless.person.present?
      headless.destroy
    end

    resource_saved = resource.save
    yield resource if block_given?
    if resource_saved
      # FIXME: DON'T EVER DO THIS!
      # HACK: DON'T EVER DO THIS!
      # NONONONOBAD: We are only doing this because the enterprise service
      #              can't accept a password with a standard hash.
      session["stashed_password"] = sign_up_params["password"]
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)
        location = after_sign_in_path_for(resource)
        flash[:warning] = current_user.get_announcements_by_roles_and_portal(location) if current_user.present?
        respond_with resource, location: location
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      @validatable = devise_mapping.validatable?
      if @validatable
        @minimum_password_length = resource_class.password_length.min
      end
      respond_with resource
    end
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # You can put the params you want to permit in the empty array.
  def configure_sign_up_params
    devise_parameter_sanitizer.for(:sign_up) << :oim_id
  end

  # You can put the params you want to permit in the empty array.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.for(:account_update) << :attribute
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
