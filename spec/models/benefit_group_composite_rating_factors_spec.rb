require "rails_helper"

describe BenefitGroup, "being asked for a group size rating factor" do
  let(:carrier_profile_id) { double }
  let(:plan) { instance_double(Plan, :carrier_profile_id => carrier_profile_id) }
  let(:plan_option_kind) { "sole_source" }
  let(:group_size_of_1_factor) { double }
  let(:plan_year) { PlanYear.new(:start_on => Date.new(2015, 2, 1)) }

  subject { BenefitGroup.new(:plan_option_kind => plan_option_kind, :plan_year => plan_year) }

  describe "when the rating model is 'simple'" do
    before(:each) do
      allow(subject).to receive(:use_simple_employer_calculation_model?).and_return(true)
    end

    it "provides a factor of 1.0" do
      expect(subject.group_size_factor_for(plan)).to eq 1.0
    end
  end

  describe "when the complex rating model is in use" do
    before(:each) do
      allow(subject).to receive(:use_simple_employer_calculation_model?).and_return(false)
    end

    describe "when the plan year is not sole-source" do
      let(:plan_option_kind) { "metal_level" }

      before :each do
        allow(EmployerGroupSizeRatingFactorSet).to receive(:value_for).with(carrier_profile_id, 2015, 1).and_return(group_size_of_1_factor)
      end

      it "returns the value for a group size of 1" do
        expect(subject.group_size_factor_for(plan)).to eq group_size_of_1_factor
      end
    end

    describe "when the plan year is sole source, and the group size is 3" do
      before :each do
        allow(EmployerGroupSizeRatingFactorSet).to receive(:value_for).with(carrier_profile_id, 2015, 3).and_return(group_size_of_1_factor)
        allow(subject).to receive(:group_size_count).and_return(3)
      end

      it "returns the value for a group size of 3" do
        expect(subject.group_size_factor_for(plan)).to eq group_size_of_1_factor
      end
    end
  end
end

describe BenefitGroup, "for a plan year which should estimate the group size" do
  let(:employer_profile) { build(:employer_profile) }
  let(:plan_year) { PlanYear.new(:start_on => Date.new(2015, 2, 1), employer_profile: employer_profile) }

  let(:census_employees) do
    [
      instance_double(CensusEmployee, :expected_to_enroll? => true, employer_profile: employer_profile, :is_included_in_participation_rate? => true),
      instance_double(CensusEmployee, :expected_to_enroll? => true, employer_profile: employer_profile, :is_included_in_participation_rate? => true),
      instance_double(CensusEmployee, :expected_to_enroll? => false, employer_profile: employer_profile, :is_included_in_participation_rate? => false)
    ]
  end

  subject { BenefitGroup.new(plan_year: plan_year) }

  before :each do
    allow(plan_year).to receive(:estimate_group_size?).and_return(true)
    allow(employer_profile).to receive(:census_employees).and_return(census_employees)
    #allow(CensusEmployee).to receive(:find_all_by_benefit_group).with(subject).and_return(census_employees)
  end

  it "provides the group_size_count based on the employees expected to enroll" do
    expect(subject.group_size_count).to eq 2
  end
end

describe BenefitGroup, "for a plan year which should NOT estimate the group size" do
  let(:plan_year) { PlanYear.new(:start_on => Date.new(2015, 2, 1)) }
  let(:benefit_group_assignment_1) { instance_double(BenefitGroupAssignment, :active_enrollments => [enrollment_1, enrollment_2]) }
  let(:benefit_group_assignment_2) { instance_double(BenefitGroupAssignment, :active_enrollments => [enrollment_3]) }
  let(:enrollment_1) { instance_double(HbxEnrollment, :dental? => false) }
  let(:enrollment_2) { instance_double(HbxEnrollment, :dental? => true) }
  let(:enrollment_3) { instance_double(HbxEnrollment, :dental? => false) }

  subject { BenefitGroup.new(:plan_year => plan_year) }

  before :each do
    allow(plan_year).to receive(:estimate_group_size?).and_return(false)
    allow(BenefitGroupAssignment).to receive(:by_benefit_group_id).with(subject.id).and_return([benefit_group_assignment_1, benefit_group_assignment_2])
  end

  it "provides the group_size_count based on the employees who have enrolled" do
    expect(subject.group_size_count).to eq 2
  end
end

describe BenefitGroup, "being asked for a composite rating participation rate factor" do
  let(:carrier_profile_id) { double }
  let(:plan) { instance_double(Plan, :carrier_profile_id => carrier_profile_id) }
  let(:plan_option_kind) { "sole_source" }
  let(:group_size_of_1_factor) { double }
  let(:plan_year) { PlanYear.new(:start_on => Date.new(2015, 2, 1), employer_profile: employer_profile) }
  let(:benefit_group_assignment_1) { instance_double(BenefitGroupAssignment, :active_and_waived_enrollments => [enrollment_1, enrollment_2]) }
  let(:benefit_group_assignment_2) { instance_double(BenefitGroupAssignment, :active_and_waived_enrollments => [enrollment_3]) }
  let(:enrollment_1) { instance_double(HbxEnrollment, :dental? => false) }
  let(:enrollment_2) { instance_double(HbxEnrollment, :dental? => true) }
  let(:enrollment_3) { instance_double(HbxEnrollment, :dental? => false) }
  let(:employer_profile) { build(:employer_profile) }
  let(:ces){ double("CensusEmployees") }

  let(:census_employees) do
    [
      instance_double(CensusEmployee, :expected_to_enroll_or_valid_waive? => true),
      instance_double(CensusEmployee, :expected_to_enroll_or_valid_waive? => true),
      instance_double(CensusEmployee, :expected_to_enroll_or_valid_waive? => false)
    ]
  end

  subject { BenefitGroup.new(:plan_option_kind => plan_option_kind, :plan_year => plan_year) }

  before :each do
    allow(plan_year).to receive(:estimate_group_size?).and_return(plan_year_should_estimate)
    allow(employer_profile).to receive(:census_employees).and_return(ces)
    allow(ces).to receive(:select).and_return(census_employees)
  end

  describe "for a plan year which should estimate the group size" do
    let(:plan_year_should_estimate) { true }

    before(:each) do
      allow(EmployerParticipationRateRatingFactorSet).to receive(:value_for).with(carrier_profile_id, 2015, be_within(0.01).of(66.666)).and_return(1.0)
    end

    it "provides a factor of 1.0" do
      expect(subject.composite_participation_rate_factor_for(plan)).to eq 1.0
    end
  end

  describe "for a plan year which should NOT estimate the group size" do
    let(:plan_year_should_estimate) { false }

    before(:each) do
    allow(BenefitGroupAssignment).to receive(:by_benefit_group_id).with(subject.id).and_return([benefit_group_assignment_1, benefit_group_assignment_2])
      allow(EmployerParticipationRateRatingFactorSet).to receive(:value_for).with(carrier_profile_id, 2015, be_within(0.01).of(66.666)).and_return(1.0)
    end

    it "provides a factor of 1.0" do
      expect(subject.composite_participation_rate_factor_for(plan)).to eq 1.0
    end
  end
end

describe BenefitGroup, "being asked for a sic code factor" do
  let(:carrier_profile_id) { double }
  let(:plan) { instance_double(Plan, :carrier_profile_id => carrier_profile_id) }
  let(:plan_year) { PlanYear.new(:recorded_sic_code => sic_code, :start_on => Date.new(2015, 2, 1)) }
  let(:sic_code) { "12343234" }

  subject { BenefitGroup.new(:plan_year => plan_year) }

  describe "when the rating model is 'simple'" do
    before(:each) do
      allow(subject).to receive(:use_simple_employer_calculation_model?).and_return(true)
    end

    it "provides a factor of 1.0" do
      expect(subject.sic_factor_for(plan)).to eq 1.0
    end
  end

  describe "when the rating model is not simple" do
    before :each do
      expect(SicCodeRatingFactorSet).to receive(:value_for).with(carrier_profile_id, 2015, sic_code).and_return(1.0)
    end

    it "provides a factor of 1.0" do
      expect(subject.sic_factor_for(plan)).to eq 1.0
    end
  end
end

describe BenefitGroup, "being asked for rating area" do
  let(:plan_year) { PlanYear.new(:recorded_rating_area => rating_area) }
  let(:rating_area) { "12343234" }

  subject { BenefitGroup.new(:plan_year => plan_year) }

  it "provides the rating area" do
    expect(subject.rating_area).to eq(rating_area)
  end
end

describe BenefitGroup, "given a composite tier contribution with an estimated premium value, and a plan year that should estimate" do
  let(:plan_year) { PlanYear.new(:start_on => Date.new(2015, 2, 1)) }
  let(:estimated_tier_premium) { 1234.23 }
  let(:composite_rating_tier) { CompositeRatingTier::NAMES.first }

  subject do
    BenefitGroup.new(:plan_year => plan_year, :composite_tier_contributions => [
      CompositeTierContribution.new(:composite_rating_tier => composite_rating_tier, :estimated_tier_premium => estimated_tier_premium)
    ])
  end

  before :each do
    allow(plan_year).to receive(:estimate_group_size?).and_return(true)
  end

  it "has the estimated premium" do
    expect(subject.composite_rating_tier_premium_for(composite_rating_tier)).to eq estimated_tier_premium
  end
end

describe BenefitGroup, "given a composite tier contribution with a final premium value, and a plan year that should NOT estimate" do
  let(:plan_year) { PlanYear.new(:start_on => Date.new(2015, 2, 1)) }
  let(:final_tier_premium) { 1234.23 }
  let(:composite_rating_tier) { CompositeRatingTier::NAMES.first }

  subject do
    BenefitGroup.new(:plan_year => plan_year, :composite_tier_contributions => [
      CompositeTierContribution.new(:composite_rating_tier => composite_rating_tier, :final_tier_premium => final_tier_premium)
    ])
  end

  before :each do
    allow(plan_year).to receive(:estimate_group_size?).and_return(false)
  end

  it "has the final premium" do
    expect(subject.composite_rating_tier_premium_for(composite_rating_tier)).to eq final_tier_premium
  end
end

describe BenefitGroup, "given a composite tier contribution with an employer contribution percent" do
  let(:employer_contribution_percent) { 50.00 }
  let(:composite_rating_tier) { CompositeRatingTier::NAMES.first }

  subject do
    BenefitGroup.new(:composite_tier_contributions => [
      CompositeTierContribution.new(:composite_rating_tier => composite_rating_tier, :employer_contribution_percent => employer_contribution_percent)
    ])
  end

  it "has the correct contribution factor" do
    expect(subject.composite_employer_contribution_factor_for(composite_rating_tier)).to eq 0.5
  end
end

describe BenefitGroup, "asked for a composite rating tier base factor for a plan and a particular composite rating tier" do
  let(:composite_rating_tier) { CompositeRatingTier::NAMES.first }
  let(:carrier_profile_id) { double }
  let(:plan) { instance_double(Plan, :carrier_profile_id => carrier_profile_id) }
  let(:composite_rating_tier_base_factor) { 1.01 }
  let(:plan_year) { PlanYear.new(:start_on => Date.new(2015, 2, 1)) }

  subject do
    BenefitGroup.new(:plan_year => plan_year)
  end

  before :each do
    allow(CompositeRatingTierFactorSet).to receive(:value_for).with(carrier_profile_id, 2015, composite_rating_tier).and_return(composite_rating_tier_base_factor)
  end

  it "has the correct composite rating tier factor" do
    expect(subject.composite_rating_tier_factor_for(composite_rating_tier, plan)).to eq composite_rating_tier_base_factor
  end
end
