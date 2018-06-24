class SessionTimeoutController < ApplicationController
  # These are what prevent check_time_until_logout and
  # reset_user_clock from resetting users' Timeoutable
  # Devise "timers"
  prepend_before_action :skip_timeout, only: [:check_time_until_logout, :has_user_timed_out]
  def skip_timeout
    request.env["devise.skip_trackable"] = true
  end

  skip_before_filter :authenticate_user!, only: [:has_user_timed_out]

  def check_time_until_logout
    @time_left = Devise.timeout_in - (Time.now - user_session["last_request_at"]).to_i.round
    if @time_left <= 0
      sign_out(current_user)
      respond_to do |format|
        format.js { render 'devise/sessions/sign_out_user' }
      end
    else
      respond_to do |format|
        format.js { render 'devise/sessions/session_expiration_warning' }
      end
    end
  end

  def reset_user_clock
    # Receiving an arbitrary request from a client automatically
    # resets the Devise Timeoutable timer.
    head :ok
  end
end
