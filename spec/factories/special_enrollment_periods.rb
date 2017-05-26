FactoryGirl.define do
  factory :special_enrollment_period do
    family
    qle_on  { 10.days.ago.to_date }
    qualifying_life_event_kind_id { FactoryGirl.create(:qualifying_life_event_kind)._id }
    start_on { qle_on }
    end_on  { qle_on + 30.days }
    effective_on  { qle_on.end_of_month + 1 }
    submitted_at  { Time.now }
    effective_on_kind { "date_of_event" }
    

    trait :expired do
      qle_on  { 1.year.ago.to_date }
      # qualifying_life_event_kind
      # begin_on  { qle_on }
      # end_on  { qle_on + 30.days }
      # effective_on  { qle_on.end_of_month + 1 }
      # submitted_at  { Time.now }
    end
  end

end
