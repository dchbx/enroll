FactoryGirl.define do
  factory(:application, :class => FinancialAssistance::Application) do
    family
    assistance_year TimeKeeper.date_of_record.year
    submitted_at {2.months.ago}
    aasm_state "determined"
  end
end