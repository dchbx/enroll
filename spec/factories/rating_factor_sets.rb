FactoryGirl.define do
  factory :rating_factor_set do
    # association :person, ssn: '123456789', dob: "1/1/1965", gender: "female", first_name: "Sarah", last_name: "Smile"
    association :carrier_profile

    active_year { TimeKeeper.date_of_record.year }
    max_integer_factor_key nil
    default_factor_value 1.0
    rating_factor_entries [ FactoryGirl.build(:rating_factor_entry) ]
  end

  factory :employer_group_size_rating_factor_set, class: EmployerGroupSizeRatingFactorSet, parent: :rating_factor_set do
    association :carrier_profile

    active_year { TimeKeeper.date_of_record.year }
    max_integer_factor_key 10
    default_factor_value 1.0
    rating_factor_entries [ FactoryGirl.build(:rating_factor_entry) ]
  end

  factory :composite_rating_tier_factor_set, class: CompositeRatingTierFactorSet, parent: :rating_factor_set do
    association :carrier_profile
    active_year { TimeKeeper.date_of_record.year }
    rating_factor_entries [ FactoryGirl.build(:rating_factor_entry, factor_key: 'employee_only'),
                            FactoryGirl.build(:rating_factor_entry, factor_key: 'family'),
                            FactoryGirl.build(:rating_factor_entry, factor_key: 'employee_and_spouse'),
                            FactoryGirl.build(:rating_factor_entry, factor_key: 'employee_and_one_or_more_dependents')
                          ]
  end

end
