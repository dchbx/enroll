require "rails_helper"

describe CompositeRatingListBillPrecalculator, "given:
- a plan
- an hbx_enrollment
- a benefit group
" do
  let(:enrollment) { instance_double(HbxEnrollment, :class => HbxEnrollment, :hbx_enrollment_members => [subscriber]) }
  let(:subscriber) { instance_double(HbxEnrollmentMember, :class => HbxEnrollmentMember) }
  let(:benefit_group) { instance_double(BenefitGroup, :plan_year => plan_year, :rating_area => rating_area) }
  let(:plan_id) { double }
  let(:plan) { instance_double(Plan, :id => plan_id) }
  let(:plan_year) { instance_double(PlanYear, :start_on => plan_year_start_date) }
  let(:plan_year_start_date) { Date.new(2015, 2, 1) }
  let(:expected_total_premium) { 122.22 }
  let(:rating_area) { "A RATING AREA" }

  subject { CompositeRatingListBillPrecalculator.new(plan, enrollment, benefit_group) }

  before :each do
    allow(subscriber).to receive(:age_on_effective_date).and_return(25)
    allow(Caches::PlanDetails).to receive(:lookup_rate_with_area).with(plan_id, plan_year_start_date, 25, rating_area).and_return(123.45)
    allow(benefit_group).to receive(:sic_factor_for).with(plan).and_return(1.1)
    allow(benefit_group).to receive(:group_size_factor_for).with(plan).and_return(0.9)
    allow(benefit_group).to receive(:composite_participation_rate_factor_for).with(plan).and_return(1.0)
  end

  it "gives the correct total premium" do
    expect(subject.total_premium).to eq expected_total_premium
  end
end

describe CompositeRatingListBillPrecalculator, "given:
- a plan
- a census employee
- a benefit group
" do
  let(:census_employee) { instance_double(CensusEmployee, :class => CensusEmployee, :census_dependents => []) }
  let(:benefit_group) { instance_double(BenefitGroup, :plan_year => plan_year, :rating_area => rating_area) }
  let(:plan_id) { double }
  let(:plan) { instance_double(Plan, :id => plan_id) }
  let(:plan_year) { instance_double(PlanYear, :start_on => plan_year_start_date) }
  let(:plan_year_start_date) { Date.new(2015, 2, 1) }
  let(:expected_total_premium) { 122.22 }
  let(:rating_area) { "A RATING AREA" }

  subject { CompositeRatingListBillPrecalculator.new(plan, census_employee, benefit_group) }

  before :each do
    allow(census_employee).to receive(:age_on).with(plan_year_start_date).and_return(25)
    allow(Caches::PlanDetails).to receive(:lookup_rate_with_area).with(plan_id, plan_year_start_date, 25, rating_area).and_return(123.45)
    allow(benefit_group).to receive(:sic_factor_for).with(plan).and_return(1.1)
    allow(benefit_group).to receive(:group_size_factor_for).with(plan).and_return(0.9)
    allow(benefit_group).to receive(:composite_participation_rate_factor_for).with(plan).and_return(1.0)
  end

  it "gives the correct total premium" do
    expect(subject.total_premium).to eq expected_total_premium
  end

end
