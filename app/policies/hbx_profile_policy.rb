class HbxProfilePolicy < ApplicationPolicy

  # Acts as the entire Pundit Policy for app/controllers/translations_controller.rb
  def can_view_or_change_translations?
    user_hbx_staff_role&.permission&.name == "super_admin"
  end

  def view_admin_tabs?
    role = user_hbx_staff_role
    return false unless role
    role.permission.view_admin_tabs
  end

  def modify_admin_tabs?
    role = user_hbx_staff_role
    return false unless role
    role.permission.modify_admin_tabs
  end

  def view_the_configuration_tab?
    role = user_hbx_staff_role
    return false unless role
    role.permission.view_the_configuration_tab
  end

  def can_submit_time_travel_request?
    role = user_hbx_staff_role
    return false unless role
    return false unless role.permission.name == "super_admin"
    role.permission.can_submit_time_travel_request
  end

  def send_broker_agency_message?
    role = user_hbx_staff_role
    return false unless role
    role.permission.send_broker_agency_message
  end

  def approve_broker?
    role = user_hbx_staff_role
    return false unless role
    role.permission.approve_broker
  end

  def approve_ga?
    role = user_hbx_staff_role
    return false unless role
    role.permission.approve_ga
  end

  def can_extend_open_enrollment?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_extend_open_enrollment
  end

  def can_modify_plan_year?
    return true unless (role = user.person.hbx_staff_role)

    role.permission.can_modify_plan_year
  end

  def can_create_benefit_application?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_create_benefit_application?
  end

  def can_change_fein?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_change_fein
  end

  def can_force_publish?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_force_publish
  end

  def can_send_secure_message?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_send_secure_message
  end

  def can_manage_settings?
    role = user_hbx_staff_role
    return false unless role
    return false unless role.permission.name == "super_admin"
    role.permission.can_manage_settings
  end

  def show?
    @user.has_role?(:hbx_staff) ||
      @user.has_role?(:csr) ||
      @user.has_role?(:assister)
  end

  def index?
    @user.has_role? :hbx_staff
  end

  def employer_index?
    index?
  end

  def family_index?
    index?
  end

  def broker_agency_index?
    index?
  end

  def configuration?
    index?
  end

  def new?
    @user.has_role? :hbx_staff
  end

  def edit?
    if @user.has_role?(:hbx_staff)
      @record.id == @user.try(:person).try(:hbx_staff_role).try(:hbx_profile).try(:id)
    else
      false
    end
  end

  def inbox?
    index?
  end

  def create?
    new?
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def set_date?
    index?
  end

  def can_add_sep?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_add_sep
  end

  def access_identity_verification_sub_tab?
    return @user.person.hbx_staff_role.permission.can_access_identity_verification_sub_tab if (@user.person && @user.person.hbx_staff_role)
    return false
  end

  def access_outstanding_verification_sub_tab?
    return @user.person.hbx_staff_role.permission.can_access_outstanding_verification_sub_tab if (@user.person && @user.person.hbx_staff_role)
    return false
  end

  def can_access_accept_reject_identity_documents?
    return @user.person.hbx_staff_role.permission.can_access_accept_reject_identity_documents if (@user.person && @user.person.hbx_staff_role)
    return false
  end

  def can_access_accept_reject_paper_application_documents?
    return @user.person.hbx_staff_role.permission.can_access_accept_reject_paper_application_documents if (@user.person && @user.person.hbx_staff_role)
    return false
  end

  def can_delete_identity_application_documents?
    return @user.person.hbx_staff_role.permission.can_delete_identity_application_documents if (@user.person && @user.person.hbx_staff_role)
    return false
  end

  def can_access_user_account_tab?
    return @user.person.hbx_staff_role.permission.can_access_user_account_tab if @user&.person && @user.person.hbx_staff_role

    false
  end

  def can_add_pdc?
    role = user_hbx_staff_role
    return false unless role

    role.permission.can_add_pdc
  end


  private

  def user_hbx_staff_role
    person = user.person
    return nil unless person
    person.hbx_staff_role
  end
end
