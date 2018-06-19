FactoryGirl.define do
  factory :sponsored_benefits_organization, class: 'SponsoredBenefits::Organizations::Organization' do
    legal_name "ACME Co."

    fein do
      Forgery('basic').text(:allow_lower   => false,
        :allow_upper   => false,
        :allow_numeric => true,
        :allow_special => false, :exactly => 9)
    end

    office_locations do
      [ build(:sponsored_benefits_office_location, :primary) ]
    end
  end
end
