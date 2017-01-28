FactoryGirl.define do
  factory :resident_role do
    association :person
    dob "01/01/1980"
    gender 'male'
    is_state_resident 'yes'
    is_applicant 'yes'
    paper_applications {[FactoryGirl.build(:paper_application)]}
    bookmark_url nil
  end

  factory(:resident_role_person, {class: ::Person}) do
    first_name { Forgery(:name).first_name }
    last_name { Forgery(:name).first_name }
    gender { Forgery(:personal).gender }
    dob Date.new(1980, 1, 1)
  end


  factory(:resident_role_object, {class: ::ResidentRole}) do
    is_applicant true
    person { FactoryGirl.create(:resident_role_person) }
  end

end
