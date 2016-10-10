class Exchanges::ResidentsController < ApplicationController
  include ApplicationHelper
  include VlpDoc
  include ErrorBubble


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
    resident_role = person.consumer_role

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
    binding.pry
    if params.permit(:build_consumer_role)[:build_consumer_role].present? && session[:person_id]
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
      found_person = @resident_candidate.match_person
      if found_person.present?
        session[:person_id] = found_person.id
        binding.pry

        format.html { render 'match' }
      else
        format.html { render 'no_match' }
      end
    end
  end

  def show
  end

  def create
    binding.pry
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
    create_sso_account(current_user, @person, 15, "resident") do
      respond_to do |format|
        format.html {
          redirect_to :action => "edit", :id => @resident_role.id
        }
      end
    end
  end

  def edit
    set_resident_bookmark_url
    binding.pry
    @resident_role = ResidentRole.find(params[:id])
    @resident_role.build_nested_models_for_person
  end

  private
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

end
