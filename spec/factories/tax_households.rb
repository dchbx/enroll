FactoryGirl.define do
  factory :tax_household do
    household
    sequence(:hbx_assigned_id) { |n| 42 + n }
    is_eligibility_determined true
    effective_starting_on   { TimeKeeper.date_of_record.beginning_of_year }
    effective_ending_on     { TimeKeeper.date_of_record.end_of_year }
    submitted_at            ( TimeKeeper.datetime_of_record )
  end
end
