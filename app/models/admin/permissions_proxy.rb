# frozen_string_literal: true

module Admin
  # Implements the nil object pattern around users who might not have
  # people or permission objects.
  class PermissionsProxy
    attr_reader :permission_target

    def initialize(user)
      @permission_target = resolve_target(user)
    end

    def resolve_target(user)
      return NullPermission.new unless user.person
      person = user.person
      return NullPermission.new unless person.hbx_staff_role
      staff_role = person.hbx_staff_role
      return NullPermission.new unless staff_role.permission
      staff_role.permission
    end

    delegate :view_agency_staff, :manage_agency_staff, :to => :permission_target
  end
end
