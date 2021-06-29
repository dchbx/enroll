# frozen_string_literal: true

module Users
  class PasswordsController < Devise::PasswordsController
    before_action :confirm_identity, only: [:create]
    layout 'bootstrap_4'

    rescue_from 'Mongoid::Errors::DocumentNotFound', with: :user_not_found
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

    def user_not_found
      respond_to do |format|
        format.html { respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name)) }
        format.js
      end
    end

    private

    def user
      @user ||= User.find_by(email: params[:user][:email])
    end

    def confirm_identity
      return true if current_user&.has_role?('hbx_staff')

      if user.identity_confirmed_token.present? && user.identity_confirmed_token != params[:user][:identity_confirmed_token]
        flash[:error] = "Something went wrong, please try again"
        redirect_to new_user_password_path
        false
      end
    end

    protected

    def after_resetting_password_path_for(_resource_name)
      root_url
    end
  end
end
