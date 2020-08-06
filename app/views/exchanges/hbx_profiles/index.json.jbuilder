# frozen_string_literal: true

json.array!(@hbx_profiles) do |hbx_profile|
  json.extract! hbx_profile, :id
  json.url hbx_profile_url(hbx_profile, format: :json)
end
