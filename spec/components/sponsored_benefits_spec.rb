require 'rails_helper'

if ("SponsoredBenefits::Engine".constantize rescue nil)
  Dir[Rails.root.join("components/sponsored_benefits/spec/factories/sponsored_benefits_*.rb")].each do |f|
    require f
  end
  Dir[Rails.root.join("components/sponsored_benefits/spec/**/*_spec.rb")].each do |f|
    require f
  end
end
