FactoryGirl.define do
  factory :announcement do
    content 'announcement msg'
    start_date (TimeKeeper.date_of_record - 10.days)
    end_date (TimeKeeper.date_of_record + 10.days)
    audiences ['Employer']
  end
end

