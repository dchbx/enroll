class UsersController < ApplicationController
  before_filter :confirm_existing_password, only: [:change_password]

  def confirm_lock
    params.permit!
    authorize User, :lockable?
    @user_id  = params[:user_action_id]
  end

  def lockable
    authorize User, :lockable?
    user.lock!
    redirect_to user_account_index_exchanges_hbx_profiles_url, notice: "User #{user.email} is successfully #{user.lockable_notice}."
  rescue Pundit::NotAuthorizedError
    redirect_to user_account_index_exchanges_hbx_profiles_url, alert: "You are not authorized for this action."
  end

  def reset_password
    @user = User.find(params[:id])
    authorize User, :reset_password?
  rescue Pundit::NotAuthorizedError
    redirect_to user_account_index_exchanges_hbx_profiles_url, alert: "You are not authorized for this action."
  end

  def confirm_reset_password
    @user = User.find(params[:id])
    authorize User, :reset_password?
    @error = nil
    validate_email if params[:user].present?
    if @error.nil?
      User.send_reset_password_instructions(email: @user.email)
      redirect_to user_account_index_exchanges_hbx_profiles_url, notice: "Reset password instruction sent to user email."
    else
      render file: 'users/reset_password.js.erb'
    end
  rescue Pundit::NotAuthorizedError
    redirect_to user_account_index_exchanges_hbx_profiles_url, alert: "You are not authorized for this action."
  end

  def change_password
    user.password = params[:user][:new_password]
    user.password_confirmation = params[:user][:password_confirmation]
    if user.save!
      flash[:success] = "Password successfully changed"
    else
      flash[:error] = "We encountered a problem trying to update your password, please try again"
    end
    redirect_to personal_insured_families_path
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    @user.update_attributes(email_update_params)
  end

  def login_history
    @user_login_history = SessionIdHistory.for_user(user_id: user.id).order('created_at DESC').page(params[:page]).per(15)
  end
  
  private
  helper_method :user

  def email_update_params
    params.require(:user).permit(:email)
  end

  def validate_email
     @error = if params[:user][:email].blank?
               'Please enter a valid email'
             elsif params[:user].present? && !@user.update_attributes(email_update_params)
                @user.errors.full_messages.join.gsub('(optional) ', '')
              end
  end

  def user
    @user ||= User.find(params[:id])
  end

  def confirm_existing_password
    unless user.valid_password? params[:user][:password]
      flash[:error] = "That password does not match the one we have stored"
      redirect_to personal_insured_families_path
      return false
    end
  end
end
