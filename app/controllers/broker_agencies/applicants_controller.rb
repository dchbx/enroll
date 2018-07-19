class BrokerAgencies::ApplicantsController < ApplicationController

  before_action :find_broker_agency_profile
  before_action :check_primary_broker_role
  before_action :find_broker_applicant, only: [:edit, :update]

  def index
    @people = Person.find_all_brokers_or_staff_members_by_agency(@broker_agency_profile).sans_primary_broker(@broker_agency_profile)
    @status = params.permit(:status)[:status] || 'broker_agency_pending'
    @people = Person.brokers_or_agency_staff_with_status(@people, @status) unless @status == 'all'

    @page_alphabets = page_alphabets(@people, "last_name")

    if params[:page].present?
      page_no = cur_page_no(@page_alphabets.first)
      @broker_applicants = @people.where("last_name" => /^#{page_no}/i)
    else
      @broker_applicants = @people.to_a.first(20)
    end

    respond_to do |format|
      format.js
    end
  end

  def edit
    respond_to do |format|
      format.js
      format.html
    end
  end

  def update
    role = @broker_applicant.broker_role
    role = @broker_applicant.broker_agency_staff_roles[0] unless role
    # if params[:person] && params[:person][:broker_role_attributes] && params[:person][:broker_role_attributes][:reason]
    #   broker_role.update_attributes(:reason => params[:person][:broker_role_attributes][:reason])
    # end

    if params['decline']
      role.broker_agency_decline!
      flash[:notice] = "Applicant declined."
    elsif params['terminate']
      role.broker_agency_terminate!
      flash[:notice] = "Applicant terminated."
    else
      role.broker_agency_accept!
      flash[:notice] = "Applicant accepted successfully."
    end

    redirect_to broker_agencies_profile_path(@broker_agency_profile)
  end

  private

  def find_broker_agency_profile
    @broker_agency_profile = BrokerAgencyProfile.find(params[:profile_id])
    if @broker_agency_profile.nil?
      redirect_to broker_agencies_profiles_path(@broker_agency_profile), :flash => { :error => "Something went wrong!!" }
    end
  end

  def find_broker_applicant
    @broker_applicant = Person.find(BSON::ObjectId.from_string(params[:id]))
  end

  def check_primary_broker_role
    return true if current_user.has_hbx_staff_role?

    person = current_user.person
    return true if person.broker_role && person.broker_role.is_primary_broker?

    redirect_to broker_agencies_profiles_path(@broker_agency_profile), :flash => { :error => "You must be a Primary broker" }
  end
end
