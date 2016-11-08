class PeopleController < ApplicationController
  include ApplicationHelper
  include ErrorBubble
  include VlpDoc

  def new
    @person = Person.new
    build_nested_models
    # render action: "new", layout: "form"
  end

  def check_qle_marriage_date
    date_married = Date.parse(params[:date_val])
    start_date = Date.parse('01/10/2013')
    end_date = TimeKeeper.date_of_record

    if start_date <= date_married && date_married <= end_date
      # Qualifed
      @qualified_date = true
    else
      # Not Qualified
      @qualified_date = false
    end

    # else {
    #   var startDate = Date.parse('2013-10-01'), endDate = Date.parse(new Date()), enteredDate = Date.parse(date_value);

    #   return ((startDate <= enteredDate) && (enteredDate <= endDate));
    # }
  end

  def register_employee_dependents
    @family = Family.find(params[:id])
    @employee_role = EmployeeRole.find(params[:id])

    @family.updated_by = current_user.oim_id unless current_user.nil?
    @employee_role.updated_by = current_user.oim_id unless current_user.nil?

    # May need person init code here
    if (@family.update_attributes(@family) && @employee_role.update_attributes(@employee_role))
      @person = @employee_role.person

      if params[:commit].downcase.include?('continue')
        @organization = @employee_role.employer_profile.organization
        @employee_role = EmployeeRole.find(params[:employee_role])

        redirect_to select_plan_people_path
      end

      if params[:commit].downcase.include?('exit')
        # Logout of session
      else
        redirect_to person_person_landing(@person)
      end
    else
      render new, :error => "Please complete all required fields"
    end
  end


  # Uses identifying information to return one or more for matches in employer census
  def match_employer
  end

  def link_employer
  end

  def person_confirm
    @person = Person.find(params[:person_id])
    if params[:employer_id].to_i != 0
      @employer = Employer.find(params[:employer_id])
      #@employee = Employer
      employee_family = Employer.where(:"id" => @employer.id).where(:"employee_families.employee.ssn" => @person.ssn).last.employee_families.last
      @coverage = employee_family.dependents.present? ? "Individual + Family" : "Individual"
      @coverage_flag = "I"
    else
      @employee = @person
    end
    respond_to do |format|
      format.js {}
    end
  end

  def plan_details
    #add_employee_role
  end

  def dependent_details
    add_employee_role
    @employer_profile = @employee_role.employer_profile
    @employer = @employer_profile.organization
    @person = @employee_role.person
    # @employee = @employer_profile.find_employee_by_person(@person)
    # employee_family = Organization.find(@employer.id).employee_family_details(@person)
    # @employee = employee_family.census_employee
    build_nested_models
  end

  def add_employee_role
    @person = Person.find(params[:person_id])
    @employer_profile = Organization.find(params[:organization_id]).employer_profile
    employer_census_family = @employer_profile.linkable_employee_family_by_person(@person)

    #calling add_employee_role when linkable employee family present
    if employer_census_family.present?
      enroll_parms = {}
      enroll_parms[:user] = current_user
      enroll_parms[:employer_profile] = @employer_profile
      enroll_parms[:ssn] = @person.ssn
      enroll_parms[:last_name] = @person.last_name
      enroll_parms[:first_name] = @person.first_name
      enroll_parms[:gender] = @person.gender
      enroll_parms[:dob] = @person.dob
      enroll_parms[:name_sfx] = @person.name_sfx
      enroll_parms[:name_pfx] = @person.name_pfx
      enroll_parms[:hired_on] = params[:hired_on]

      @employee_role, @family = Factories::EnrollmentFactory.add_employee_role(enroll_parms)
    else
      @employee_role = @person.employee_roles.first
      @family = @person.primary_family
    end
  end

  def add_dependents
    @person = Person.find(params[:person_id])
    @employer = Organization.find(params[:organization_id])
    # employee_family = Organization.find(@employer.id).employee_family_details(@person)
    @employee = @person.employee_roles.first
    @dependent = FamilyMember.new(family: @person.primary_family)
  end

  def save_dependents
    @person = Person.find(params[:person])
    @employer = Organization.find(params[:employer])
    family = @person.primary_family
    member = Person.new(dependent_params)
    new_dependent = FamilyMember.new(id: params[:family_member][:id], person: member)
    @dependent = family.family_members.where(_id: new_dependent.id).first
    if @dependent.blank?
      @dependent = family.family_members.new(id: params[:family_member][:id], person: member)
      respond_to do |format|
        if member.save && @dependent.save
          @person.person_relationships.create(kind: params[:family_member][:primary_relationship], relative_id: member.id)
          family.households.first.coverage_households.first.coverage_household_members.find_or_create_by(applicant_id: params[:family_member][:id])
          format.js { flash.now[:notice] = "Family Member Added." }
        else
          format.js { flash.now[:error_msg] = "Error in Family Member Addition. #{member.errors.full_messages}" }
        end
      end
    else
      if @dependent.update_attributes(dependent_params)
        respond_to do |format|
          format.js { flash.now[:notice] = "Family Member Updated." }
        end
      else
        respond_to do |format|
          format.js { flash.now[:error_msg] = "Error in Family Member Edit. #{member.errors.full_messages}" }
        end
      end
    end
  end

  def remove_dependents
    @person = Person.find(params[:person_id])
    @employer = Organization.find(params[:organization_id])
    @family = @person.primary_family
    @dependent = @family.family_members.where(_id: params[:id]).first
    if !@dependent.nil?
      @family_member_id = @dependent._id
      if !@dependent.is_primary_applicant
        @dependent.destroy
        @person.person_relationships.where(relative_id: @dependent.person_id).destroy_all
        @family.households.first.coverage_households.first.coverage_household_members.where(applicant_id: params[:id]).destroy_all
        @flash = "Family Member Removed"
      else
        @flash = "Primary member can not be deleted"
      end
    else
      @family_member_id = params[:id]
    end
    respond_to do |format|
      format.js { flash.now[:notice] = @flash }
    end
  end

  def get_census_employee(id)
    CensusEmployee.find(id)
  end

  def update
    sanitize_person_params
    @person = find_person(params[:id])
    clean_duplicate_addresses
    @person.updated_by = current_user.oim_id unless current_user.nil?

    if @person.has_active_consumer_role? && request.referer.include?("insured/families/personal")
      update_vlp_documents(@person.consumer_role, 'person')
      redirect_path = personal_insured_families_path
    else

      redirect_path = family_account_path
    end


    respond_to do |format|
      if @person.update_attributes(person_params)
        format.html { redirect_to redirect_path, notice: 'Person was successfully updated.' }
        format.json { head :no_content }
      else
        @person.addresses = @old_addresses
        if @person.has_active_consumer_role?
          bubble_consumer_role_errors_by_person(@person)
          @vlp_doc_subject = get_vlp_doc_subject_by_consumer_role(@person.consumer_role)
        end
        build_nested_models
        person_error_megs = @person.errors.full_messages.join('<br/>') if @person.errors.present?
        format.html { redirect_to redirect_path, alert: "Person update failed. #{person_error_megs}" }
        # format.html { redirect_to edit_insured_employee_path(@person) }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    sanitize_person_params
    @person = Person.find_or_initialize_by(encrypted_ssn: Person.encrypt_ssn(params[:person][:ssn]), date_of_birth: params[:person][:dob])

    # Delete old sub documents
    @person.addresses.each {|address| address.delete}
    @person.phones.each {|phone| phone.delete}
    @person.emails.each {|email| email.delete}

    # person_params
    respond_to do |format|
      if @person.update_attributes(person_params)
        format.html { redirect_to insured_employee_path(@person), notice: 'Person was successfully created.' }
        format.json { render json: @person, status: :created, location: @person }
      else
        build_nested_models
        format.html { render action: "new" }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @person = Person.find(params[:id])
    build_nested_models
  end

   def show
    @person = Person.find(params[:id])
    @employer_profile= EmployerProfile.find_all_by_person(@person).first

    build_nested_models
  end

  def select_plan
    hbx_enrollment_id = params.require(:hbx_enrollment_id)

    Caches::MongoidCache.allocate(CarrierProfile)

    @person = current_user.person
    @hbx_enrollment = find_hbx_enrollment(hbx_enrollment_id)
    @benefit_group = @hbx_enrollment.benefit_group
    @reference_plan = @hbx_enrollment.coverage_kind == 'dental' ? @benefit_group.dental_reference_plan : @benefit_group.reference_plan

    @plans = @benefit_group.elected_plans.entries.collect() do |plan|
      PlanCostDecorator.new(plan, @hbx_enrollment, @benefit_group, @reference_plan)
    end
  end

  def enroll_family
    @hbx_enrollment = HbxEnrollment.find(params[:hbx_enrollment_id])
  end

  def get_member
    member = find_person(params[:id])
    render partial: 'people/landing_pages/member_address', locals: {person: member}
  end

private

  def safe_find(klass, id)
    # puts "finding #{klass} #{id}"
    begin
      klass.find(id)
    rescue
      nil
    end
  end

  def find_person(id)
    safe_find(Person, id)
  end

  def find_organization(id)
    safe_find(Organization, id)
  end

  def find_hbx_enrollment(id)
    safe_find(HbxEnrollment, id)
  end

  def build_nested_models
    ["home","mobile","work","fax"].each do |kind|
       @person.phones.build(kind: kind) if @person.phones.select{|phone| phone.kind == kind}.blank?
    end

    Address::KINDS.each do |kind|
      @person.addresses.build(kind: kind) if @person.addresses.select{|address| address.kind == kind}.blank?
    end

    ["home","work"].each do |kind|
       @person.emails.build(kind: kind) if @person.emails.select{|email| email.kind == kind}.blank?
    end
  end

  def sanitize_person_params
    if person_params["addresses_attributes"].present?
      person_params["addresses_attributes"].each do |key, address|
        if address["city"].blank? && address["zip"].blank? && address["address_1"].blank?
          params["person"]["addresses_attributes"].delete("#{key}")
        end
      end
      params["person"]["addresses_attributes"] = person_params["addresses_attributes"].values.uniq #fix unexpected duplicate issue
    end

    if person_params["phones_attributes"].present?
      person_params["phones_attributes"].each do |key, phone|
        if phone["full_phone_number"].blank?
          params["person"]["phones_attributes"].delete("#{key}")
        end
      end
    end

    if person_params["emails_attributes"].present?
      person_params["emails_attributes"].each do |key, email|
        if email["address"].blank?
          params["person"]["emails_attributes"].delete("#{key}")
        end
      end
    end
  end

  def person_params
    params.require(:person).permit(*person_parameters_list)
  end

  def person_parameters_list
    [
      { :addresses_attributes => [:kind, :address_1, :address_2, :city, :state, :zip, :id] },
      { :phones_attributes => [:kind, :full_phone_number, :id] },
      { :emails_attributes => [:kind, :address, :id] },
      { :consumer_role_attributes => [:contact_method, :language_preference, :id]},
      { :employee_roles_attributes => [:id, :contact_method, :language_preference]},

      :first_name,
      :middle_name,
      :last_name,
      :name_sfx,
      :gender,
      :us_citizen,
      :is_incarcerated,
      :language_code,
      :is_disabled,
      :race,
      :is_consumer_role,
      :naturalized_citizen,
      :eligible_immigration_status,
      :indian_tribe_member,
      {:ethnicity => []},
      :tribal_id,
      :no_dc_address,
      :no_dc_address_reason, 
      :id
    ]
  end

  def dependent_params
    params.require(:family_member).reject{|k, v| k == "id" or k =="primary_relationship"}.permit!
  end

  def clean_duplicate_addresses
    @old_addresses = @person.addresses
    @person.addresses = [] #fix unexpected duplicates issue
  end

end
