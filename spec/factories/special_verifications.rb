FactoryGirl.define do
  factory :special_verification do
    due_date {TimeKeeper.date_of_record + 95.days}
    verification_type "Citizenship"
    updated_by { FactoryGirl.build(:user).id}

    after(:build) do |sv, evaluator|
      p = FactoryGirl.create(:person, :with_consumer_role)
      p.consumer_role.special_verifications << sv
      p.save
    end
  end
end
