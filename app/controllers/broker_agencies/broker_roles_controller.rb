### Handles Broker Registration requests made by anonymous users. Authentication disbaled for this controller.
class BrokerAgencies::BrokerRolesController < ApplicationController
  before_action :assign_filter_and_agency_type

  def new_broker
    @broker_candidate = Forms::BrokerCandidate.new
    @organization = Forms::BrokerAgencyProfile.new
    respond_to do |format|
      format.html { render 'new' }
      format.js
    end
  end

  def new_staff_member
    @broker_candidate = Forms::BrokerCandidate.new

    respond_to do |format|
      format.js
    end
  end

  def new_broker_agency
    @organization = Forms::BrokerAgencyProfile.new

    respond_to do |format|
      format.html { render 'new' }
      format.js
    end
  end

  def search_broker_agency
    orgs = Organization.has_broker_agency_profile.or({legal_name: /#{params[:broker_agency_search]}/i}, {"fein" => /#{params[:broker_agency_search]}/i})

    @broker_agency_profiles = orgs.present? ? orgs.map(&:broker_agency_profile) : []
  end

  def favorite
    @broker_role = BrokerRole.find(params[:id])
    @general_agency_profile = GeneralAgencyProfile.find(params[:general_agency_profile_id])
    if @broker_role.present? && @general_agency_profile.present?
      favorite_general_agencies = @broker_role.search_favorite_general_agencies(@general_agency_profile.id)
      if favorite_general_agencies.present?
        favorite_general_agencies.destroy_all
        @favorite_status = false
      else
        @broker_role.favorite_general_agencies.create(general_agency_profile_id: @general_agency_profile.id)
        @favorite_status = true
      end
    end

    respond_to do |format|
      format.js
    end
  end

  def create
    # failed_recaptcha_message = "We were unable to verify your reCAPTCHA.  Please try again."
    notice = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
    if params[:person].present?
      @broker_candidate = ::Forms::BrokerCandidate.new(applicant_params)
      # if verify_recaptcha(model: @broker_candidate, message: failed_recaptcha_message) && @broker_candidate.save
      if @broker_candidate.save
        flash[:notice] = notice
        redirect_to broker_registration_path
      else
        @filter = params[:person][:broker_applicant_type]
        render 'new'
      end
    else
      @organization = ::Forms::BrokerAgencyProfile.new(primary_broker_role_params)
      @organization.languages_spoken = params.require(:organization)[:languages_spoken].reject!(&:empty?) if params.require(:organization)[:languages_spoken].present?
      # if verify_recaptcha(model: @organization, message: failed_recaptcha_message) && @organization.save
      if @organization.save
        flash[:notice] = notice
        redirect_to broker_registration_path
      else
        @agency_type = 'new'
        render "new"
      end
    end
  end

  private

  # def convert_to_string(languages_spoken)
  #   # return languages_spoken unless languages_spoken.respond_to?(:join)
  #   languages_spoken.reject!(&:empty?) #.join(',')
  # end

  def assign_filter_and_agency_type
    @filter = params[:filter] || 'broker'
    @agency_type = params[:agency_type] || 'new'
  end

  def primary_broker_role_params
    params.require(:organization).permit(
      :first_name, :last_name, :dob, :email, :npn, :legal_name, :dba,
      :fein, :is_fake_fein, :entity_kind, :home_page, :market_kind, :languages_spoken,
      :working_hours, :accept_new_clients,
      :office_locations_attributes => [
        :address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip],
        :phone_attributes => [:kind, :area_code, :number, :extension]
      ]
    )
  end

  def applicant_params
    params.require(:person).permit(:first_name, :last_name, :dob, :email, :npn, :broker_agency_id, :broker_applicant_type,
     :market_kind, {:languages_spoken => []}, :working_hours, :accept_new_clients, 
     :addresses_attributes => [:kind, :address_1, :address_2, :city, :state, :zip])
  end
end
