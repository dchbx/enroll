FactoryGirl.define do
  factory :organization do
    legal_name  "Turner Agency, Inc"
    dba         "Turner Brokers"
    home_page   "http://www.example.com"
    office_locations  { [FactoryGirl.build(:office_location, :primary),
                         FactoryGirl.build(:office_location)] }

    fein do
      Forgery('basic').text(:allow_lower   => false,
                            :allow_upper   => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 9)
    end
  end

  factory :broker_agency, class: Organization do
    sequence(:legal_name) {|n| "Broker Agency#{n}" }
    sequence(:dba) {|n| "Broker Agency#{n}" }
    fein do
      Forgery('basic').text(:allow_lower   => false,
                            :allow_upper   => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 9)
    end
    home_page   "http://www.example.com"
    office_locations  { [FactoryGirl.build(:office_location, :primary),
                         FactoryGirl.build(:office_location)] }

    after(:create) do |organization|
      FactoryGirl.create(:broker_agency_profile, organization: organization)
    end
  end

  factory :employer, class: Organization do
    legal_name { Forgery(:name).company_name }
    dba { legal_name }

    fein do
      Forgery('basic').text(:allow_lower   => false,
                            :allow_upper   => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 9)
    end

    office_locations  { [FactoryGirl.build(:office_location, :primary),
                         FactoryGirl.build(:office_location)] }

    before :create do |organization, evaluator|
      organization.employer_profile = FactoryGirl.create :employer_profile, organization: organization
    end
  end

  factory :general_agency, class: Organization do
    legal_name { Forgery(:name).company_name }
    dba { legal_name }

    fein do
      Forgery('basic').text(:allow_lower   => false,
                            :allow_upper   => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 9)
    end

    transient do
      general_agency_traits []
      general_agency_attributes { {} }
    end

    before :create do |organization, evaluator|
      organization.office_locations.push FactoryGirl.build :office_location, :primary
    end

    after :create do |organization, evaluator|
      FactoryGirl.create :general_agency_profile, *Array.wrap(evaluator.general_agency_traits) + [:with_staff], evaluator.general_agency_attributes.merge(organization: organization)
    end
  end

  factory :general_agency_with_organization, class: Organization do
    sequence(:legal_name) {|n| "General Agency#{n}" }
    sequence(:dba) {|n| "General Agency#{n}" }
    fein do
      Forgery('basic').text(:allow_lower   => false,
                            :allow_upper   => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 9)
    end
    home_page   "http://www.example.com"
    office_locations  { [FactoryGirl.build(:office_location, :primary),
                         FactoryGirl.build(:office_location)] }

    after(:create) do |organization|
      FactoryGirl.create(:general_agency_profile, organization: organization)
    end
  end
end
