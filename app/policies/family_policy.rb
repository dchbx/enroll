class FamilyPolicy < ApplicationPolicy
  def updateable?
    return true unless role = user.person && user.person.hbx_staff_role
    role.permission.modify_family
  end

  def can_update_ssn?
    return false unless role = user.person && user.person.hbx_staff_role
    role.permission.can_update_ssn
  end

  def hbx_super_admin_visible?
    return false unless role = user.person && user.person.hbx_staff_role
    role.permission.can_update_ssn
  end

end
