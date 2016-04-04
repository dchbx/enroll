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
    sequence(:fein, 200000000)
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
        # hbx_enrollment = FactoryGirl.create(:hbx_enrollment)
        plan_year.benefit_groups.push(benefit_group = FactoryGirl.create(:benefit_group, plan_year: plan_year))

        # organization.employer_profile.census_employees = FactoryGirl.create_list(:census_employee, 5).tap do |census_employees|
        census_employes = FactoryGirl.create_list(:census_employee, 5, :with_enrolled_census_employee, employer_profile_id: organization.employer_profile.id).tap do |census_employees|
          census_employees.each do |census_employee|
            census_employee.aasm_state = "employee_role_linked"
            census_employee.benefit_group_assignments.create benefit_group: benefit_group, start_on: benefit_group.start_on, aasm_state: "coverage_selected", hbx_enrollment_id: hbx_enrollment.id
            binding.pry
            person = FactoryGirl.create :person, first_name: census_employee.first_name, middle_name: census_employee.middle_name, last_name: census_employee.last_name, ssn: census_employee.ssn, gender: census_employee.gender
            person.employee_roles.build person: person, hired_on: census_employee.hired_on, employer_profile_id: organization.employer_profile.id, census_employee_id: census_employee.id
            census_employee.save!
            person.save!
          end
        end
      end
    end
  end
end
