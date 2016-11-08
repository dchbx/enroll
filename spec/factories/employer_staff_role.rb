FactoryGirl.define do
  factory :employer_staff_role do
    person
    is_owner true
    employer_profile_id { create(:employer_profile).id }
  end

end
