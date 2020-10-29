# frozen_string_literal: true

class PortalsController < ApplicationController


  layout 'bootstrap_4_two_column'

  before_action :find_person

  def index
    @person = Person.find(params[:id])
  end

  def show; end

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