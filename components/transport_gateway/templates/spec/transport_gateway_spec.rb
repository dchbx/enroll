require 'rails_helper'

if ("TransportGateway::Engine".constantize rescue nil)
  Dir[Rails.root.join("components/transport_gateway/spec/**/*_spec.rb")].each do |f|
    require f
  end
end
