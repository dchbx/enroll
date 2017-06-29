class WizardController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :require_login
  skip_before_filter :authenticate_me!

  def show
    render :index
  end

  def create
  end
end
