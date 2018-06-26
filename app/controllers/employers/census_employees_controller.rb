class Employers::CensusEmployeesController < ApplicationController
  before_action :find_employer
  before_action :find_census_employee, only: [:edit, :update, :show, :delink, :terminate, :rehire, :benefit_group, :cobra ,:cobra_reinstate, :confirm_effective_date]
  before_action :updateable?, except: [:edit, :show, :benefit_group]
  layout "two_column"
  def new
    @census_employee = build_census_employee
    if params[:modal].present?
      respond_to do |format|
        format.js { render "employers/employer_profiles/upload_employees" }
      end

    end
  end

  def create
    @census_employee = CensusEmployee.new(census_employee_params)
    @census_employee.assign_benefit_packages(benefit_group_id: benefit_group_id, renewal_benefit_group_id: renewal_benefit_group_id)
    @census_employee.employer_profile = @employer_profile

    if @census_employee.save
      flash[:notice] = "Census Employee is successfully created."
      if @census_employee.active_benefit_group_assignment.blank?
        flash[:notice] = "Your employee was successfully added to your roster."
      end
      redirect_to employers_employer_profile_path(@employer_profile, tab: 'employees')
    else
      begin
        missing_kind = census_employee_params['email_attributes']['kind']==''
        @census_employee.errors['Email']='Kind must be selected' if missing_kind
      rescue
      end
      @reload = true
      render action: "new"
    end
    #else
      #@census_employee.benefit_group_assignments.build if @census_employee.benefit_group_assignments.blank?
      #flash[:error] = "Please select Benefit Group."
      #render action: "new"
    #end
  end

  def edit
    @census_employee.build_address unless @census_employee.address.present?
    @census_employee.build_email unless @census_employee.email.present?
    @census_employee.benefit_group_assignments.build unless @census_employee.benefit_group_assignments.present?
  end

  def update
    authorize EmployerProfile, :updateable?
    @status = params[:status]

    @census_employee.assign_benefit_packages(benefit_group_id: benefit_group_id, renewal_benefit_group_id: renewal_benefit_group_id)
    @census_employee.attributes = census_employee_params

    destroyed_dependent_ids = census_employee_params[:census_dependents_attributes].delete_if{|k,v| v.has_key?("_destroy") }.values.map{|x| x[:id]} if census_employee_params[:census_dependents_attributes]
    authorize @census_employee, :update?

    if @census_employee.attributes[:email].present? && @census_employee.attributes[:email][:address].blank?
      e = @census_employee.email
      e.destroy
      @census_employee.reload
    end

    if @census_employee.save
      if destroyed_dependent_ids.present?
        destroyed_dependent_ids.each do |g|
          census_dependent = @census_employee.census_dependents.find(g)
          census_dependent.delete
        end
      end

      flash[:notice] = "Census Employee is successfully updated."
      if benefit_group_id.blank?
        flash[:notice] += " Note: new employee cannot enroll on #{site_short_name} until they are assigned a benefit group."
      end

      redirect_to employers_employer_profile_census_employee_path(@employer_profile.id, @census_employee.id, tab: 'employees', status: params[:status])
    else
      flash[:error] = @census_employee.errors.full_messages
      redirect_to employers_employer_profile_census_employee_path(@employer_profile.id, @census_employee.id, tab: 'employees', status: params[:status])
    end
    #else
      #flash[:error] = "Please select Benefit Group."
      #render action: "edit"
    #end
  end

  def terminate
    authorize EmployerProfile, :updateable?
    status = params[:status]
    termination_date = params["termination_date"]

    if termination_date.present?
      termination_date = DateTime.strptime(termination_date, '%m/%d/%Y').try(:to_date)
      if termination_date >= (TimeKeeper.date_of_record - 60.days)
        @fa = @census_employee.terminate_employment(termination_date)
        notify_employee_of_termination
      end
    end

    respond_to do |format|
      format.js {
        if termination_date.present? && @fa
          flash[:notice] = "Successfully terminated Census Employee."
        else
          flash[:error] = "Census Employee could not be terminated: Termination date must be within the past 60 days."
        end
      }
      format.all {
        flash[:notice] = "Successfully terminated Census Employee."
      }
    end
    flash.keep(:error)
    flash.keep(:notice)
    render js: "window.location = '#{employers_employer_profile_census_employee_path(@employer_profile.id, @census_employee.id, status: status)}'"
  end

  def rehire
    authorize EmployerProfile, :updateable?
    status = params[:status]
    rehiring_date = params["rehiring_date"]
    if rehiring_date.present?
      rehiring_date = DateTime.strptime(rehiring_date, '%m/%d/%Y').try(:to_date)
    else
      rehiring_date = ""
    end
    @rehiring_date = rehiring_date
    if @rehiring_date.present? && @rehiring_date > @census_employee.employment_terminated_on
      new_census_employee = @census_employee.replicate_for_rehire
      if new_census_employee.present? # not an active family, then it is ready for rehire.#
        new_census_employee.hired_on = @rehiring_date
        if new_census_employee.valid? && @census_employee.valid?
          @census_employee.save
          new_census_employee.save

          # for new_census_employee
          new_census_employee.build_address if new_census_employee.address.blank?
          @census_employee = new_census_employee
          flash[:notice] = "Successfully rehired Census Employee."
        else
          flash[:error] = "Error during rehire."
        end
      else # active family, dont replicate for rehire, just return error
        flash[:error] = "Census Employee is already active."
      end
    elsif @rehiring_date.blank?
      flash[:error] = "Please enter rehiring date."
    else
      flash[:error] = "Rehiring date can't occur before terminated date."
    end
    flash.keep(:error)
    flash.keep(:notice)
    render js: "window.location = '#{employers_employer_profile_path(@employer_profile.id, :tab=>'employees', status: params[:status])}'"
  end

  def cobra
    cobra_date = params["cobra_date"]

    if cobra_date.present?
      @cobra_date = DateTime.strptime(cobra_date, '%m/%d/%Y').try(:to_date)
    else
      @cobra_date = ""
    end

    if @cobra_date.present? && @census_employee.can_elect_cobra?
      if @census_employee.update_for_cobra(@cobra_date, current_user)
        flash[:notice] = "Successfully update Census Employee."
      else
        flash[:error] = "COBRA cannot be initiated for this employee because termination date is over 6 months in the past. Please contact #{site_short_name} at #{contact_center_phone_number} for further assistance."
      end
    else
      flash[:error] = "Please enter cobra date."
    end
  end

  def confirm_effective_date
    confirmation_type = params[:type]
    render "#{confirmation_type}_effective_date"
  end

  def cobra_reinstate
    if @census_employee.reinstate_eligibility!
      flash[:notice] = "Successfully update Census Employee."
    else
      flash[:error] = "Unable to update Census Employee."
    end
  end

  def show
    @family = @census_employee.employee_role.person.primary_family if @census_employee.employee_role.present?
    past_enrollment_statuses = HbxEnrollment::TERMINATED_STATUSES
    @past_enrollments = @census_employee.employee_role.person.primary_family.all_enrollments.select {
        |hbx_enrollment| (past_enrollment_statuses.include? hbx_enrollment.aasm_state) && (@census_employee.benefit_group_assignments.map(&:id).include? hbx_enrollment.benefit_group_assignment_id)
    } if @census_employee.employee_role.present?

    @past_enrollments = @past_enrollments.reject { |r| r.coverage_expired?} if @census_employee.employee_role.present?
    @status = params[:status] || ''
  end

  def delink
    employee_role = @census_employee.employee_role
    if employee_role.present?
      employee_role.census_employee_id = nil
      user = employee_role.person.user
      user.roles.delete("employee")
    end
    benefit_group_assignment = @census_employee.benefit_group_assignments.last
    hbx_enrollment = benefit_group_assignment.hbx_enrollment
    benefit_group_assignment.delink_coverage
    @census_employee.delink_employee_role

    if @census_employee.valid?
      user.try(:save)
      employee_role.try(:save)
      benefit_group_assignment.save
      hbx_enrollment.destroy
      @census_employee.save

      flash[:notice] = "Successfully delinked census employee."
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      flash[:alert] = "Delink census employee failure."
      redirect_to employers_employer_profile_path(@employer_profile)
    end
  end

  def benefit_group
    @census_employee.benefit_group_assignments.build unless @census_employee.benefit_group_assignments.present?
  end

  def change_expected_selection
    if params[:ids]
      begin
        census_employees = CensusEmployee.find(params[:ids])
        census_employees.each do |census_employee|
          census_employee.update_attributes(:expected_selection=>params[:expected_selection].downcase)
        end
        render json: { status: 200, message: 'successfully submitted the selected Employees participation status' }
      rescue => e
        render json: { status: 500, message: 'An error occured while submitting employees participation status' }
      end
    end
  end

  def notify_employee_of_termination
    begin
      ShopNoticesNotifierJob.perform_later(@census_employee.id.to_s, "employee_termination_notice")
    rescue Exception => e
      (Rails.logger.error { "Unable to deliver termination notice to #{@census_employee.full_name} due to #{e.inspect}" }) unless Rails.env.test?
    end
  end

  private

  def updateable?
    authorize ::EmployerProfile, :updateable?
  end

  def benefit_group_id
    params[:census_employee][:benefit_group_assignments_attributes]["0"][:benefit_group_id] rescue nil
  end

  def renewal_benefit_group_id
    params[:census_employee][:renewal_benefit_group_assignments][:benefit_group_id] rescue nil
  end

  def census_employee_params
=begin
    [:dob, :hired_on].each do |attr|
      if params[:census_employee][attr].present?
        params[:census_employee][attr] = DateTime.strptime(params[:census_employee][attr].to_s, '%m/%d/%Y').try(:to_date)
      end
    end

    census_dependents_attributes = params[:census_employee][:census_dependents_attributes]
    if census_dependents_attributes.present?
      census_dependents_attributes.each do |id, dependent_params|
        if census_dependents_attributes[id][:dob].present?
          params[:census_employee][:census_dependents_attributes][id][:dob] = DateTime.strptime(dependent_params[:dob].to_s, '%m/%d/%Y').try(:to_date)
        end
      end
    end
=end

    params.require(:census_employee).permit(:id, :employer_profile_id,
        :id, :first_name, :middle_name, :last_name, :name_sfx, :dob, :ssn, :gender, :hired_on, :employment_terminated_on, :is_business_owner, :existing_cobra, :cobra_begin_date,
        :address_attributes => [ :id, :kind, :address_1, :address_2, :city, :state, :zip ],
        :email_attributes => [:id, :kind, :address],
      :census_dependents_attributes => [
          :id, :first_name, :last_name, :middle_name, :name_sfx, :dob, :gender, :employee_relationship, :_destroy, :ssn
        ]
      )
  end

  def find_employer
    @employer_profile = EmployerProfile.find(params["employer_profile_id"])
  end

  def find_census_employee
    id = params[:id] || params[:census_employee_id]
    @census_employee = CensusEmployee.find(id)
  end

  def build_census_employee
    @census_employee = CensusEmployee.new
    @census_employee.build_address
    @census_employee.build_email
    @census_employee.benefit_group_assignments.build
    @census_employee
  end

  private

end
