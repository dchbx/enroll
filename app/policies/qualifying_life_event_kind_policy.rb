# frozen_string_literal: true

class QualifyingLifeEventKindPolicy < ApplicationPolicy

  def can_manage_qles?
    role = user_hbx_staff_role
    return false unless role
    role.permission.can_manage_qles
  end

  private

  def user_hbx_staff_role
    person = user.person
    return nil unless person
    person.hbx_staff_role
  end
end
