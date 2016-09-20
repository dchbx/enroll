class FamilyPolicy < ApplicationPolicy
  def updateable?
  	return true unless role = user.person && user.person.hbx_staff_role
    role.permission.modify_family
  end
  
  def can_update_ssn?
  	return false unless role = user.person && user.person.hbx_staff_role
    role.permission.id  = Permission.hbx_staff.id
   end

end


