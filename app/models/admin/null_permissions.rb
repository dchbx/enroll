# frozen_string_literal: true

module Admin
  # Null object implementation of Permission
  class NullPermission
    def view_agency_staff
      false
    end

    def manage_agency_staff
      false
    end
  end
end