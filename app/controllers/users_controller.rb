# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :confirm_existing_password, only: [:change_password]
  before_action :set_user, except: [:confirm_lock, :unsupported_browser, :index, :show]

  def index
    redirect_to root_path
  end

  def show
    redirect_to root_path
  end

  def confirm_lock
    authorize User, :lockable?
    @user_id  = params[:user_action_id]
  rescue Pundit::NotAuthorizedError
    flash[:alert] = "You are not authorized for this action."
    render inline: "location.reload();"
  end

  def lockable
    authorize User, :lockable?
    @user.lock!
    flash[:notice] = "User #{user.email} is successfully #{user.lockable_notice}."
    render file: 'users/lockable.js.erb'
  rescue Pundit::NotAuthorizedError
    redirect_to user_account_index_exchanges_hbx_profiles_url, alert: "You are not authorized for this action."
  end

  def reset_password
    authorize User, :reset_password?
    render file: 'users/reset_password.js.erb'
  rescue Pundit::NotAuthorizedError
    flash[:alert] = "You are not authorized for this action."
    render inline: "location.reload();"
  end

  def confirm_reset_password
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
    @user.password = params[:user][:new_password]
    @user.password_confirmation = params[:user][:password_confirmation]
    if @user.save!
      flash[:success] = "Password successfully changed"
    else
      flash[:error] = "We encountered a problem trying to update your password, please try again"
    end
    redirect_to personal_insured_families_path
  end

  def change_username_and_email
    authorize User, :change_username_and_email?
    @user_id = params[:user_id]
  end

  def confirm_change_username_and_email
    authorize User, :change_username_and_email?
    @element_to_replace_id = params[:family_actions_id]
    @email_taken = User.where(:email => params[:new_email].strip, :id.ne => @user.id).first if params[:new_email]
    @username_taken = User.where(:oim_id => params[:new_oim_id].strip, :id.ne => @user.id).first if params[:new_oim_id]
    if @email_taken.present? || @username_taken.present?
      @matches = true
    else
      @user.oim_id = params[:new_oim_id] if params[:new_oim_id] != params[:current_oim_id]
      @user.email = params[:new_email] if params[:new_email] && (params[:new_email] != params[:current_email])
      begin
        @user.modifier = current_user
        @user.save!
      rescue StandardError => e
        @errors = @user.errors.messages
      end
    end
    respond_to do |format|
      format.js { render "change_username_and_email"} if @errors
      format.js { render "username_email_result"}
    end
  end

  def edit; end

  def update
    @user.update_attributes(email_update_params)
  end

  def login_history
    authorize User, :view_login_history?
    @user_login_history = SessionIdHistory.for_user(user_id: @user.id).order('created_at DESC').page(params[:page]).per(15)
  rescue Pundit::NotAuthorizedError
    flash[:alert] = "You are not authorized for this action."
    render inline: "location.reload();"
  end

  def unsupported_browser; end

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

  def set_user
    @user = User.find(params[:id])
  end

  def confirm_existing_password
    return unless @user.valid_password? params[:user][:password]

    flash[:error] = "That password does not match the one we have stored"
    redirect_to personal_insured_families_path
    false
  end
end
