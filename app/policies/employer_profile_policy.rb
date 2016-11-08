class EmployerProfilePolicy < ApplicationPolicy

  def list_enrollments?
    return false unless person=user.person
    return true unless hbx_staff = person.hbx_staff_role
    hbx_staff.permission.list_enrollments
  end

  def updateable?                
    return true unless role = user.person && user.person.hbx_staff_role
    role.permission.modify_employer
  end

  def revert_application?
    return true unless role = user.person.hbx_staff_role
    role.permission.revert_application
  end
end
