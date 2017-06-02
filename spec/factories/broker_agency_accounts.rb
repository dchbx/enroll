FactoryGirl.define do
  factory :broker_agency_account do
    employer_profile
    start_on                TimeKeeper.date_of_record
    broker_agency_profile   { FactoryGirl.create(:broker_agency_profile)}
    writing_agent           { FactoryGirl.create(:broker_role)}

    after(:build) do |bac, evaluator|
      bac.writing_agent.broker_agency_profile = bac.broker_agency_profile
      bac.writing_agent.save
    end
  end

end
