FactoryGirl.define do
  factory(:assisted_verification, :class => FinancialAssistance::AssistedVerification) do
    association :applicant
    status "unverified"
    verification_type "Income"
  end
end
