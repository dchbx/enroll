class AngularAdminApplicationPolicy < ApplicationPolicy
  def visit?
    return false unless user.has_hbx_staff_role?
    permission = user.person.hbx_staff_role.permission
    return false unless permission
    permission.view_agency_staff
  end

  def list_agencies?
    visit?
  end

  def list_agency_staff?
    visit?
  end

  def list_primary_agency_staff?
    visit?
  end

  def view_agency_staff_details?
    visit?
  end

  def terminate_agency_staff?
    return false unless user.has_hbx_staff_role?
    permission = user.person.hbx_staff_role.permission
    return false unless permission
    permission.manage_agency_staff
  end

  def update_staff?
    return false unless user.has_hbx_staff_role?
    permission = user.person.hbx_staff_role.permission
    return false unless permission
    permission.manage_agency_staff
  end
end
