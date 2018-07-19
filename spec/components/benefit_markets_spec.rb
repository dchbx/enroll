require 'rails_helper'

if ("BenefitMarkets::Engine".constantize rescue nil)
#  Dir[Rails.root.join("components/benefit_markets/spec/factories/*.rb")].each do |f|
#    require f
#  end
  Dir[Rails.root.join("components/benefit_markets/spec/**/*_spec.rb")].each do |f|
    require f
  end
end
