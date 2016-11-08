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

    trait :with_expired_and_active_plan_years do
      before :create do |organization, evaluator|
        organization.employer_profile = FactoryGirl.create :employer_profile, organization: organization, registered_on: Date.new(2015,12,1)
      end
      after :create do |organization, evaluator|
        expired_plan_year = FactoryGirl.create :plan_year, employer_profile: organization.employer_profile, aasm_state: :expired, :start_on => Date.new(2015,10,1), :end_on => Date.new(2016,9,30),
          :open_enrollment_start_on => Date.new(2015,8,11), :open_enrollment_end_on => Date.new(2015, 9, 13), fte_count: 5
        active_plan_year = FactoryGirl.create :plan_year, employer_profile: organization.employer_profile, aasm_state: :active, :start_on => Date.new(2016,10,1), :end_on => Date.new(2017,9,30),
          :open_enrollment_start_on => Date.new(2016,8,11), :open_enrollment_end_on => Date.new(2016,9,13), fte_count: 5
        expired_benefit_group = FactoryGirl.create :benefit_group, :with_valid_dental, plan_year: expired_plan_year
        active_benefit_group = FactoryGirl.create :benefit_group, :with_valid_dental, plan_year: active_plan_year
      end
    end

    trait :with_active_and_renewal_plan_years do
      before :create do |organization, evaluator|
        organization.employer_profile = FactoryGirl.create :employer_profile, organization: organization
      end
      after :create do |organization, evaluator|
        active_plan_year = FactoryGirl.create :plan_year, employer_profile: organization.employer_profile, aasm_state: :active, :start_on => Date.new(2016 - 1, 5, 1), :end_on => Date.new(2016, 4, 30),
        :open_enrollment_start_on => Date.new(2016 - 1, 4, 1), :open_enrollment_end_on => Date.new(2016 - 1, 4, 10), fte_count: 5
        renewing_plan_year = FactoryGirl.create :plan_year, employer_profile: organization.employer_profile, aasm_state: :renewing_enrolled, :start_on => Date.new(2016, 5, 1), :end_on => Date.new(2016+1, 4, 30),
        :open_enrollment_start_on => Date.new(2016, 4, 1), :open_enrollment_end_on => Date.new(2016, 4, 10), fte_count: 5
        benefit_group = FactoryGirl.create :benefit_group, :with_valid_dental, plan_year: active_plan_year
        renewing_benefit_group = FactoryGirl.create :benefit_group, :with_valid_dental, plan_year: renewing_plan_year
      end
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

    trait :with_insured_employees do
      after :create do |organization, evaluator|

        plan_year = FactoryGirl.create :next_month_plan_year, employer_profile: organization.employer_profile
        plan_year.benefit_groups.push(benefit_group = FactoryGirl.create(:benefit_group, plan_year: plan_year, relationship_benefits: [relationship_benefit = FactoryGirl.build(:relationship_benefit)]))

        # data to create an enrollment
        family = FactoryGirl.create(:family, :with_primary_family_member)
        household = FactoryGirl.create(:household, family: family)
        hbx_enrollment_member = FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month)
        hbx_enrollment = FactoryGirl.create(:hbx_enrollment, household: household, plan: FactoryGirl.create(:plan), benefit_group: benefit_group, hbx_enrollment_members: [hbx_enrollment_member], coverage_kind: "health" )
        # end of data to create an enrollment

        census_employees = FactoryGirl.create_list(:census_employee, 1, :with_enrolled_census_employee, employer_profile_id: organization.employer_profile.id).tap do |census_employees|
          census_employees.each do |census_employee|
            census_employee.aasm_state = "employee_role_linked"
            census_employee.benefit_group_assignments.create benefit_group: benefit_group, start_on: benefit_group.start_on, aasm_state: "coverage_selected", hbx_enrollment_id: hbx_enrollment.id

            person = FactoryGirl.create :person, first_name: census_employee.first_name, middle_name: census_employee.middle_name, last_name: census_employee.last_name, ssn: census_employee.ssn, gender: census_employee.gender
            person.employee_roles.build person: person, hired_on: census_employee.hired_on, employer_profile_id: organization.employer_profile.id, census_employee_id: census_employee.id

            hbx_enrollment.benefit_group_assignment_id = census_employee.benefit_group_assignments.first.id
            hbx_enrollment.save!
            census_employee.save!
            person.save!
          end
        end
      end
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
