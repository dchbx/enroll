class PersonPolicy < ApplicationPolicy
  def updateable?
  	return true unless role = user.person.hbx_staff_role
    role.permission.modify_family
  end
end

