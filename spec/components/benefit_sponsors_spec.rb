require 'rails_helper'

if ("BenefitSponsors::Engine".constantize rescue nil)
#  Dir[Rails.root.join("components/benefit_markets/spec/factories/*.rb")].each do |f|
#    require f
#  end
#  Dir[Rails.root.join("components/benefit_sponsors/spec/factories/benefit_sponsors_*.rb")].each do |f|
#    require f
#  end
  Dir[Rails.root.join("components/benefit_sponsors/spec/**/*_spec.rb")].each do |f|
    require f
  end
end
