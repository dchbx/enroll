class Employers::EmployerStaffRolesController < Employers::EmployersController

  before_action :check_access_to_employer_profile,:updateable?

  def create

    dob = DateTime.strptime(params[:dob], '%m/%d/%Y').try(:to_date)
    employer_profile = EmployerProfile.find(params[:id])
    first_name = (params[:first_name] || '').strip
    last_name = (params[:last_name] || '').strip
    email = params[:email]
    @status, @result = Person.add_employer_staff_role(first_name, last_name, dob, email, employer_profile)
    flash[:error] = ('Role was not added because '  + @result) unless @status
    redirect_to edit_employers_employer_profile_path(employer_profile.organization)
  end

  def approve
    employer_profile = EmployerProfile.find(params[:id])
    person = Person.find(params[:staff_id])
    role = person.employer_staff_roles.detect{|role| role.is_applicant? &&
      role.employer_profile_id.to_s == params[:id]}
    if role && role.approve && role.save!
      flash[:notice] = 'Role is approved'
    else
      flash[:error] = 'Please contact HBX Admin to report this error'
    end
    redirect_to edit_employers_employer_profile_path(employer_profile.organization)
  end

  # For this person find an employer_staff_role that match this employer_profile_id and mark the role inactive
  def destroy
    employer_profile_id = params[:id]
    employer_profile = EmployerProfile.find(employer_profile_id)
    staff_id = params[:staff_id]
    staff_list =Person.staff_for_employer(employer_profile).map(&:id)
    if staff_list.count == 1 && staff_list.first.to_s == staff_id
      flash[:error] = 'Please add another staff role before deleting this role'
    else
      @status, @result = Person.deactivate_employer_staff_role(staff_id, employer_profile_id)
      @status ? (flash[:notice] = 'Staff role was deleted') : (flash[:error] = ('Role was not deactivated because '  + @result))
    end

    redirect_to edit_employers_employer_profile_path(employer_profile.organization)
  end

  private

  def updateable?
    authorize EmployerProfile, :updateable?
  end
  # Check to see if current_user is authorized to access the submitted employer profile
  def check_access_to_employer_profile
    employer_profile = EmployerProfile.find(params[:id])
    policy = ::AccessPolicies::EmployerProfile.new(current_user)
    policy.authorize_edit(employer_profile, self)
  end

end



