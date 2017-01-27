class Insured::EmployeeRolesController < ApplicationController
  before_action :check_employee_role, only: [:new, :privacy, :welcome, :search]
  before_action :check_employee_role_permissions_edit, only: [:edit]
  before_action :check_employee_role_permissions_update, only: [:update]
  include ErrorBubble

  def welcome
  end

  def privacy
  end

  def search
    @no_previous_button = true
    @no_save_button = true
    @person = Forms::EmployeeCandidate.new
    respond_to do |format|
      format.html
    end
  end

  def match
    @no_save_button = true
    @person_params = params.require(:person).merge({user_id: current_user.id})
    @employee_candidate = Forms::EmployeeCandidate.new(@person_params)
    @person = @employee_candidate
    if @employee_candidate.valid?
      found_census_employees = @employee_candidate.match_census_employees.select{|census_employee| census_employee.is_active? }
      if found_census_employees.empty?
        # @person = Factories::EnrollmentFactory.construct_consumer_role(params.permit!, current_user)

        respond_to do |format|
          format.html { render 'no_match' }
        end
      else
        @employment_relationships = Factories::EmploymentRelationshipFactory.build(@employee_candidate, found_census_employees)
        respond_to do |format|
          format.html { render 'match' }
        end
      end
    else
      respond_to do |format|
        format.html { render 'search' }
      end
    end
  end

  def create
    @employment_relationship = Forms::EmploymentRelationship.new(params.require(:employment_relationship))
    @employee_role, @family = Factories::EnrollmentFactory.construct_employee_role(actual_user, @employment_relationship.census_employee, @employment_relationship)
    if @employee_role.present? && (@employee_role.census_employee.present? && @employee_role.census_employee.is_linked?)
      @person = Forms::EmployeeRole.new(@employee_role.person, @employee_role)
      session[:person_id] = @person.id
      create_sso_account(current_user, @employee_role.person, 15,"employee") do
        build_nested_models
        respond_to do |format|
          format.html { redirect_to :action => "edit", :id => @employee_role.id }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to :back, alert: "You can not enroll as another employee"}
      end
    end
  end

  def edit
    set_employee_bookmark_url
    @person = Forms::EmployeeRole.new(@employee_role.person, @employee_role)
    if @person.present?
      @family = @person.primary_family
      build_nested_models
    end
  end

  def update
    save_and_exit =  params['exit_after_method'] == 'true'
    person = Person.find(params.require(:id))
    object_params = params.require(:person).permit(*person_parameters_list)
    @employee_role = person.employee_roles.detect { |emp_role| emp_role.id.to_s == object_params[:employee_role_id].to_s }
    @person = Forms::EmployeeRole.new(person, @employee_role)
    @person.addresses = [] #fix unexpected duplicates issue
    if @person.update_attributes(object_params)
      if save_and_exit
        respond_to do |format|
          format.html {redirect_to destroy_user_session_path}
        end
      else
        # set_employee_bookmark_url
        redirect_path = insured_family_members_path(employee_role_id: @employee_role.id)
        if @person.primary_family && @person.primary_family.active_household
          if @person.primary_family.active_household.hbx_enrollments.any?
            redirect_path = insured_root_path
          end
        end
        respond_to do |format|
          format.html { redirect_to redirect_path }
        end
      end
    else
      if save_and_exit
        respond_to do |format|
          format.html {redirect_to destroy_user_session_path}
        end
      else
        bubble_address_errors_by_person(@person)
        build_nested_models
        respond_to do |format|
          format.html { render "edit" }
        end
      end
    end
  end

  def new_message_to_broker
    @person = current_user.person
    @family = @person.primary_family
    @hbx_enrollment = (@family.latest_household.try(:hbx_enrollments).active || []).last
    @employee_role = @person.employee_roles.first #should be latest active
    @employer_profile = @employee_role.employer_profile
    @broker_agency_accounts = @employer_profile.broker_agency_accounts
    @broker = @broker_agency_accounts.first.writing_agent
  end

  def send_message_to_broker
    @person = current_user.person
    @employee_role = @person.employee_roles.first #should be latest active
    @employer_profile = @employee_role.employer_profile
    @broker_agency_accounts = @employer_profile.broker_agency_accounts
    @broker = @broker_agency_accounts.first.writing_agent
    UserMailer.message_to_broker(@person, @broker, params).deliver_now
    redirect_to insured_plan_shopping_path(:id => params[:hbx_enrollment_id])
  end

  def build_nested_models
    ["home","mobile","work","fax"].each do |kind|
      @person.phones.build(kind: kind) if @person.phones.select{|phone| phone.kind == kind}.blank?
    end

    Address::KINDS.each do |kind|
      @person.addresses.build(kind: kind) if @person.addresses.select{|address| address.kind.to_s.downcase == kind}.blank?
    end

    ["home","work"].each do |kind|
      @person.emails.build(kind: kind) if @person.emails.select{|email| email.kind == kind}.blank?
    end
  end

  def person_parameters_list
    [
      :employee_role_id,
      { :addresses_attributes => [:kind, :address_1, :address_2, :city, :state, :zip, :id] },
      { :phones_attributes => [:kind, :full_phone_number, :id] },
      { :emails_attributes => [:kind, :address, :id] },
      { :employee_roles_attributes => [:id, :contact_method, :language_preference]},
      :first_name,
      :last_name,
      :middle_name,
      :name_pfx,
      :name_sfx,
      :date_of_birth,
      :ssn,
      :gender
    ]
  end

  def redirect_to_check_employee_role
    redirect_to search_insured_employee_index_path
  end

  def show
    #PATH REACHED FOR UNKNOWN REASONS, POSSIBLY DUPLICATE PERSONS SO USER, URL ARE LOGGED
    message={}
    message[:message] ="insured/employee_role/show is not a valid route, "
    message[:user] = current_user.oim_id
    message[:url] = request.original_url
    log(message, severity: 'error')

    redirect_to search_insured_employee_index_path
  end

  private

  def check_employee_role_permissions_edit
    @employee_role = EmployeeRole.find(params.require(:id))
    policy = ::AccessPolicies::EmployeeRole.new(current_user)
    policy.authorize_employee_role(@employee_role, self)
  end

  def check_employee_role_permissions_update
    @employee_role = EmployeeRole.find(params.require(:person).require(:employee_role_id))
    policy = ::AccessPolicies::EmployeeRole.new(current_user)
    policy.authorize_employee_role(@employee_role, self)
  end

  def check_employee_role
    set_current_person(required: false)
    if @person.try(:employee_roles).try(:last)
      redirect_to @person.employee_roles.last.bookmark_url || family_account_path
    else
      current_user.last_portal_visited = search_insured_employee_index_path
      current_user.save!
    end
  end
end
