class AngularAdminApplicationPolicy < ApplicationPolicy
  def visit?
    return false unless user.has_hbx_staff_role?
    permission = user.person.hbx_staff_role.permission
    return false unless permission
    permission.approve_broker &&
      permission.approve_ga &&
      permission.view_admin_tabs &&
      permission.can_change_fein &&
      permission.modify_admin_tabs &&
      permission.can_access_user_account_tab &&
      permission.view_login_history &&
      permission.view_the_configuration_tab &&
      permission.view_personal_info_page 
  end
end