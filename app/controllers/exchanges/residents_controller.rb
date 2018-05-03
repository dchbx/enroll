class Exchanges::ResidentsController < ApplicationController
  include ApplicationHelper
  include Pundit
  include VlpDoc
  include ErrorBubble

  before_action :find_resident_role, only: [:edit, :update]
  before_action :authorize_user

  after_action :create_initial_market_transition, only: [:create]

  def index
    @resident_enrollments = Person.where(:resident_enrollment_id.nin =>  ['', nil]).map(&:resident_enrollment)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def begin_resident_enrollment
    session[:person_id] = nil
    session[:original_application_type] = params['original_application_type']
    redirect_to search_exchanges_residents_path
  end

  def resume_resident_enrollment
    session[:person_id] = params[:person_id]
    session[:original_application_type] = params['original_application_type']
    person = Person.find(params[:person_id])
    resident_role = person.resident_role

    if resident_role && resident_role.bookmark_url
      redirect_to bookmark_url_path(resident_role.bookmark_url)
    else
      redirect_to family_account_path
    end
  end

  def search
    @no_previous_button = true
    @no_save_button = true
    if params[:aqhp].present?
      session[:individual_assistance_path] = true
    else
      session.delete(:individual_assistance_path)
    end
    if params.permit(:build_resident_role)[:build_resident_role].present? && session[:person_id]
      person = Person.find(session[:person_id])

      @person_params = person.attributes.extract!("first_name", "middle_name", "last_name", "gender")
      @person_params[:ssn] = Person.decrypt_ssn(person.encrypted_ssn)
      @person_params[:dob] = person.dob.strftime("%Y-%m-%d")

      @person = Forms::ResidentCandidate.new(@person_params)
    else
      @person = Forms::ResidentCandidate.new
    end
    respond_to do |format|
      format.html
    end
  end

  def match
    @no_save_button = true
    @person_params = params.require(:person).merge({user_id: current_user.id})
    @resident_candidate = Forms::ResidentCandidate.new(@person_params)
    @person = @resident_candidate
    respond_to do |format|
      if found_person = @resident_candidate.match_person
        session[:person_id] = found_person.id
        format.html { render 'match' }
      else
        format.html { render 'no_match' }
      end
    end
  end

  def show
  end

  def build
    set_current_person(required: false)
    build_person_params
    render 'match'
  end



  def create
    #binding.pry
    begin
      @resident_role = Factories::EnrollmentFactory.construct_resident_role(params.permit!, actual_user)
      if @resident_role.present?
        @person = @resident_role.person
        session[:person_id] = @person.id
      else
      # not logging error because error was logged in construct_consumer_role
        render file: 'public/500.html', status: 500
        return
      end
    rescue Exception => e
      flash[:error] = set_error_message(e.message)
      redirect_to search_exchanges_residents_path
      return
    end

    respond_to do |format|
      format.html {
        redirect_to :action => "edit", :id => @resident_role.id
      }
    end
  end

  def edit
    set_resident_bookmark_url
    @resident_role.build_nested_models_for_person
  end

  def update
    save_and_exit =  params['exit_after_method'] == 'true'
    if save_and_exit
      respond_to do |format|
        format.html {redirect_to destroy_user_session_path}
      end
    else
      @resident_role.build_nested_models_for_person
      @resident_role.update_by_person(params.require(:person).permit(*person_parameters_list))
      redirect_to ridp_bypass_exchanges_residents_path
    end
  end

  def ridp_bypass
    set_current_person
    if session[:original_application_type] == 'paper'
      redirect_to insured_family_members_path(:resident_role_id => @person.resident_role.id)
      return
    else
      set_resident_bookmark_url
      redirect_to insured_family_members_path(:resident_role_id => @person.resident_role.id)
    end
  end

  def find_sep
    @hbx_enrollment_id = params[:hbx_enrollment_id]
    @change_plan = params[:change_plan]
    @employee_role_id = params[:employee_role_id]


    @next_ivl_open_enrollment_date = HbxProfile.current_hbx.try(:benefit_sponsorship).try(:renewal_benefit_coverage_period).try(:open_enrollment_start_on)

    @market_kind = (params[:resident_role_id].present? && params[:resident_role_id] != 'None') ? 'coverall' : 'individual'

    render :layout => 'application'
  end

  private

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore

    flash[:error] = "Access not allowed for #{policy_name}.#{exception.query}, (Pundit policy)"
      respond_to do |format|
      format.json { redirect_to destroy_user_session_path }
      format.html { redirect_to destroy_user_session_path }
      format.js   { redirect_to destroy_user_session_path }
    end
  end

  def authorize_user
    authorize ResidentRole
  end

  def person_parameters_list
    [
      { :addresses_attributes => [:kind, :address_1, :address_2, :city, :state, :zip] },
      { :phones_attributes => [:kind, :full_phone_number] },
      { :emails_attributes => [:kind, :address] },
      { :consumer_role_attributes => [:contact_method, :language_preference]},
      :first_name,
      :last_name,
      :middle_name,
      :name_pfx,
      :name_sfx,
      :dob,
      :ssn,
      :no_ssn,
      :gender,
      :language_code,
      :is_incarcerated,
      :is_disabled,
      :race,
      :is_consumer_role,
      :is_resident_role,
      {:ethnicity => []},
      :us_citizen,
      :naturalized_citizen,
      :eligible_immigration_status,
      :indian_tribe_member,
      :tribal_id,
      :no_dc_address,
      :no_dc_address_reason
    ]
  end

  def create_initial_market_transition
    transition = IndividualMarketTransition.new
    transition.role_type = "resident"
    transition.submitted_at = TimeKeeper.datetime_of_record
    transition.reason_code = "generating_resident_role"
    transition.effective_starting_on = TimeKeeper.datetime_of_record
    transition.user_id = current_user.id
    Person.find(session[:person_id]).individual_market_transitions << transition
  end


  def set_error_message(message)
    if message.include? "year too big to marshal"
      return "Date of birth cannot be more than 110 years ago"
    else
      return message
    end
  end

  def build_person_params
   @person_params = {:ssn =>  Person.decrypt_ssn(@person.encrypted_ssn)}

    %w(first_name middle_name last_name gender).each do |field|
      @person_params[field] = @person.attributes[field]
    end

    @person_params[:dob] = @person.dob.strftime("%Y-%m-%d")
    @person_params.merge!({user_id: current_user.id})
  end

  def find_resident_role
    @resident_role = ResidentRole.find(params.require(:id))
  end
end
