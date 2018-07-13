FactoryGirl.define do
  factory :benefit_sponsors_employee_role, class: "EmployeeRole" do
    association :person
    association :employer_profile, factory: :benefit_sponsors_organizations_aca_shop_dc_employer_profile, strategy: :build
    sequence(:ssn, 111111111)
    gender "male"
    dob  {Date.new(1965,1,1)}
    hired_on {20.months.ago}
  end
end
