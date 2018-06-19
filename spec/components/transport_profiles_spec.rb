require 'rails_helper'

if ("TransportProfiles::Engine".constantize rescue nil)
  Dir[Rails.root.join("components/transport_profiles/spec/**/*_spec.rb")].each do |f|
    require f
  end
end
