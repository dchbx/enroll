# frozen_string_literal: true

class WelcomeController < ApplicationController
  layout 'bootstrap_4'
  skip_before_action :require_login

  def show_hints
    current_user.hints = !current_user.hints
    current_user.save
    render json: nil, status: :ok
  end

  def index; end

  def form_template
    # created for generic form template access at '/templates/form-template'
  end
end
