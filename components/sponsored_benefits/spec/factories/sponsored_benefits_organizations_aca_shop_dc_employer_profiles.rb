# frozen_string_literal: true

FactoryBot.define do
  factory :shop_dc_employer_profile, class: "SponsoredBenefits::Organizations::AcaShopDcEmployerProfile" do

    before(:create) do |profile, _evaluator|
      profile.office_locations << FactoryBot.build(:sponsored_benefits_office_location, :primary)
    end
  end
end
