class UsersController < ApplicationController

  def confirm_lock
    params.permit!
    @user = User.find(params[:id])
    @user_id  = params[:user_action_id]
  end

  def lockable
    user = User.find(params[:id])
    authorize User, :lockable?
    user.lock!
    redirect_to user_account_index_exchanges_hbx_profiles_url, notice: "User #{user.person.full_name} is successfully #{user.lockable_notice}."
  rescue Exception => e
    redirect_to user_account_index_exchanges_hbx_profiles_url, alert: "You are not authorized for this action."
  end
end
