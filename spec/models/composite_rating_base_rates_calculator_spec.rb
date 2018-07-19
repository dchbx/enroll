require "rails_helper"

describe CompositeRatingBaseRatesCalculator, "given:
- a benefit group with 2 enrollments
- a plan
- a higher composite factor for #{CompositeRatingTier::NAMES[2]} than #{CompositeRatingTier::NAMES[1]}
" do
  let(:enrollment_1) { double(:composite_rating_tier => CompositeRatingTier::NAMES.first) }
  let(:enrollment_2) { double(:composite_rating_tier => CompositeRatingTier::NAMES.last) }
  let(:benefit_group) { instance_double(BenefitGroup, :composite_rating_enrollment_objects => [enrollment_1, enrollment_2]) }
  let(:plan) { instance_double(Plan) }
  let(:rate_calculator_1) { instance_double(CompositeRatingListBillPrecalculator, :total_premium => premium_1) }
  let(:rate_calculator_2) { instance_double(CompositeRatingListBillPrecalculator, :total_premium => premium_2) }
  let(:premium_1) { 123.45 }
  let(:premium_2) { 456.78 }

  subject { CompositeRatingBaseRatesCalculator.new(benefit_group, plan) }

  before :each do
    allow(benefit_group).to receive(:composite_rating_tier_factor_for).with(CompositeRatingTier::NAMES[0], plan).and_return(1.0)
    allow(benefit_group).to receive(:composite_rating_tier_factor_for).with(CompositeRatingTier::NAMES[1], plan).and_return(1.0)
    allow(benefit_group).to receive(:composite_rating_tier_factor_for).with(CompositeRatingTier::NAMES[2], plan).and_return(1.7)
    allow(benefit_group).to receive(:composite_rating_tier_factor_for).with(CompositeRatingTier::NAMES[3], plan).and_return(1.4)
    allow(CompositeRatingListBillPrecalculator).to receive(:new).with(plan, enrollment_1, benefit_group).and_return(rate_calculator_1)
    allow(CompositeRatingListBillPrecalculator).to receive(:new).with(plan, enrollment_2, benefit_group).and_return(rate_calculator_2)
  end

  it "returns tier rate values" do
    expect(subject.tier_rates.keys.size).to eq 4
  end

  it "returns a base rate" do
    expect(subject.base_rate).to eq 241.76
  end

  it "is more expensive to insure #{CompositeRatingTier::NAMES[2]} vs #{CompositeRatingTier::NAMES[1]}" do
    tier_rates = subject.tier_rates
    rate_1 = tier_rates[CompositeRatingTier::NAMES[2]]
    rate_2 = tier_rates[CompositeRatingTier::NAMES[1]]
    expect(rate_1 > rate_2).to be_truthy
  end
end
