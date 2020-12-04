# frozen_string_literal: true

class AccountsController < ApplicationController


  layout 'bootstrap_4_two_column'

  before_action :find_person

  def available_accounts
    render :available_accounts
  end

  def new
    @agency = BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_new(profile_type: profile_type, portal: params[:portal])
  end


  private

  def find_person
    @person = Person.find(params[:id])
  end

  def profile_type
    @profile_type = params[:profile_type]
  end

end