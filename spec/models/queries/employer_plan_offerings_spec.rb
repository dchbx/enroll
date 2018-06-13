require "rails_helper"

describe Queries::EmployerPlanOfferings, "when constrained by service area" do
  let(:employer_profile) { double }

  subject { Queries::EmployerPlanOfferings.new(employer_profile) }

  let(:expected_query_strategy) do
    if ExchangeTestingConfigurationHelper.constrain_service_areas?
      Queries::EmployerPlanOfferingStrategies::ForServiceArea
    else
      Queries::EmployerPlanOfferingStrategies::AllAvailablePlans
    end
  end

  it "selects the service area strategy" do
    expect(subject.strategy).to be_kind_of(expected_query_strategy)
  end
end
