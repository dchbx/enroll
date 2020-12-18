class UserPolicy < ApplicationPolicy

  def lockable?
    return false unless role = user.person && user.person.hbx_staff_role
    return false unless role.permission
    role.permission.can_lock_unlock
  end

  def reset_password?
    return false unless role = user.person && user.person.hbx_staff_role
    return false unless role.permission
    role.permission.can_reset_password
  end

  def change_username_and_email?
    return false unless role = user.person && user.person.hbx_staff_role
    role.permission.can_view_username_and_email
  end

  def view_login_history?
    return false unless role = user.person && user.person.hbx_staff_role
    return false unless role.permission
    role.permission.view_login_history
  end

  def add_roles?
    return false if user.blank?
    return false if user.has_hbx_staff_role? && !can_add_staff_roles?
    true
  end

  def can_add_staff_roles?
    user.person.hbx_staff_role.permission.can_add_staff_roles
  end
end
