FactoryGirl.define do
  factory :employee_role do
    # association :person, ssn: '123456789', dob: "1/1/1965", gender: "female", first_name: "Sarah", last_name: "Smile"
    association :person
    association :employer_profile
    sequence(:ssn, 887766551)
    gender "male"
    dob  {Date.new(1965,1,1)}
    hired_on {20.months.ago}

  end

end
