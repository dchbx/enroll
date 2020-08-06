# frozen_string_literal: true

json.array!(@exchanges_hbx_staff_roles) do |exchanges_hbx_staff_role|
  json.extract! exchanges_hbx_staff_role, :id
  json.url exchanges_hbx_staff_role_url(exchanges_hbx_staff_role, format: :json)
end
