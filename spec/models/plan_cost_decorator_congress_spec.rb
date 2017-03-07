require 'rails_helper'

RSpec.describe PlanCostDecoratorCongress, dbclean: :after_each do
  let!(:plan_year)          { double("PlanYear", start_on: Date.today.beginning_of_year) }
  let!(:benefit_group)      { double("BenefitGroupCongress", plan_year: plan_year, over_one_dependents_max_amt: Money.new("97190"), employee_max_amt: Money.new("43769"), first_dependent_max_amt: Money.new("97190"), contribution_pct_as_int: 75) }
  let(:hbx_enrollment)      { HbxEnrollment.new }
  let!(:hem_employee)       { double("HbxEnrollmentMember_Employee", class: HbxEnrollmentMember, _id: "a", age_on_effective_date: 19, is_subscriber?: true , primary_relationship: "self") }
  let!(:hem_spouse)         { double("HbxEnrollmentMember_Spouse",   class: HbxEnrollmentMember, _id: "b", age_on_effective_date: 20, is_subscriber?: false, primary_relationship: "spouse") }
  let!(:hem_child_1)        { double("HbxEnrollmentMember_Child_1",  class: HbxEnrollmentMember, _id: "c", age_on_effective_date: 18, is_subscriber?: false, primary_relationship: "child") }
  let!(:hem_child_2)        { double("HbxEnrollmentMember_Child_2",  class: HbxEnrollmentMember, _id: "d", age_on_effective_date: 13, is_subscriber?: false, primary_relationship: "child") }
  let!(:hem_child_3)        { double("HbxEnrollmentMember_Child_3",  class: HbxEnrollmentMember, _id: "e", age_on_effective_date: 10, is_subscriber?: false, primary_relationship: "child") }
  let!(:hem_child_4)        { double("HbxEnrollmentMember_Child_4",  class: HbxEnrollmentMember, _id: "e", age_on_effective_date:  8, is_subscriber?: false, primary_relationship: "child") }
  # let!(:ce_employee)        { double("CensusEmployee_Employee", class: CensusEmployee , age_on: 19, employee_relationship: "employee", census_dependents: []) }
  # let!(:cd_spouse)          { double("CensusDependent_Spouse",  class: CensusDependent, age_on: 20, employee_relationship: "spouse") }
  # let!(:cd_child_1)         { double("CensusDependent_Child_1", class: CensusDependent, age_on: 18, employee_relationship: "child_under_26") }
  # let!(:cd_child_2)         { double("CensusDependent_Child_2", class: CensusDependent, age_on: 13, employee_relationship: "child_under_26") }
  # let!(:cd_child_3)         { double("CensusDependent_Child_3", class: CensusDependent, age_on: 10, employee_relationship: "child_under_26") }
  let!(:chosen_plan)        { double("ChosenPlan", id: "chosen_plan_id") }

  before do
    allow(Caches::PlanDetails).to receive(:lookup_rate) {|id, start, age| age * premium_constant}
    allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return hbx_enrollment_members
  end

  context "when no hbx enrollment members" do
    let(:plan_cost_decorator) { PlanCostDecoratorCongress.new(chosen_plan, hbx_enrollment, benefit_group) }
    let(:hbx_enrollment_members){ [] }
    it "should return total_employee_cost as zero" do
      expect(plan_cost_decorator.total_employee_cost).to eq 0.0
    end
  end

  context "rating an hbx enrollment" do
    let(:plan_cost_decorator) { PlanCostDecoratorCongress.new(chosen_plan, hbx_enrollment, benefit_group) }

    context "with no dependents" do
      let(:hbx_enrollment_members) { [hem_employee] }

      it "should be possible to construct a new plan cost decorator" do
        expect(plan_cost_decorator.class).to be PlanCostDecoratorCongress
      end

      context "below contribution cap" do
        let(:premium_constant) { 1.00 }
        before do
          allow(benefit_group).to receive(:employee_max_amt_in_cents).and_return(hem_employee.age_on_effective_date * 10)
          # allow(benefit_group).to receive(:first_dependent_max_amt_in_cents).and_return(hem_employee.age_on_effective_date * 10)
          # allow(benefit_group).to receive(:over_one_dependents_max_amt_in_cents).and_return(hem_employee.age_on_effective_date * 10)
        end

        it "should have an employer contribution for employee" do
          expect(plan_cost_decorator.employer_contribution_for(hem_employee)).to eq hem_employee.age_on_effective_date * benefit_group.contribution_pct_as_int / 100.0
        end
      end

      context "above contribution cap" do
        let(:premium_constant) { 800.0 }

        it "should have an employer contribution for employee" do
          expect(plan_cost_decorator.employer_contribution_for(hem_employee)).to eq benefit_group.employee_max_amt
        end
      end
    end

    context "with spouse, no children" do
      let(:hbx_enrollment_members) { [hem_employee, hem_spouse] }

      it "should be possible to construct a new plan cost decorator" do
        expect(plan_cost_decorator.class).to be PlanCostDecoratorCongress
      end

      context "below contribution cap" do
        let(:premium_constant) { Money.new("1000") }

        it "should have an employer contribution for employee" do
          expect(plan_cost_decorator.employer_contribution_for(hem_employee)).to eq ((plan_cost_decorator.premium_for(hem_employee)/plan_cost_decorator.total_premium)*plan_cost_decorator.total_employer_contribution).round(2)
        end
      end

      context "above contribution cap" do
        let(:premium_constant) { 100.00 }
        before do
          allow(benefit_group).to receive(:employee_max_amt_in_cents).and_return(hem_employee.age_on_effective_date )
          allow(benefit_group).to receive(:first_dependent_max_amt_in_cents).and_return(hem_spouse.age_on_effective_date * 2)
          # allow(benefit_group).to receive(:over_one_dependents_max_amt_in_cents).and_return(hem_employee.age_on_effective_date * 10)
        end

        it "should have a total employer contribution" do
          expect(plan_cost_decorator.total_employer_contribution).to eq benefit_group.first_dependent_max_amt
        end
      end

    end

    # context "with child, no spouse" do
    #   before do
    #     allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return([hem_employee, hem_child_1])
    #   end
    #
    # end
    #
    # context "with spouse and child" do
    #   before do
    #     allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return([hem_employee, hem_spouse, hem_child_1])
    #   end
    #
    # end
    #
    # context "with two children, no spouse" do
    #   before do
    #     allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return([hem_employee, hem_child_1, hem_child_2])
    #   end
    #
    # end
    #
    # context "with spouse and two children" do
    #   before do
    #     allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return([hem_employee, hem_spouse, hem_child_1, hem_child_2])
    #   end
    #
    # end
    #
    context "with spouse and four children" do
      let(:hbx_enrollment_members) { [hem_employee, hem_spouse, hem_child_1, hem_child_2, hem_child_3, hem_child_4] }

      it "should be possible to construct a new plan cost decorator" do
        expect(plan_cost_decorator.class).to be PlanCostDecoratorCongress
      end

      context "below contribution cap" do
        let(:premium_constant) { 1.00 }
        let(:premiums) { [19.00, 20.00, 18.00, 13.00, 10.00, 0.00] }
        let(:premium_sum) { premiums.inject(0.00) { |acc, prem| (acc + prem).round(2) } }
        let(:premium_percents) { premiums.collect(){|premium| (premium / premium_sum).round(2) } }

        it "should have correct list of members" do
          expect(plan_cost_decorator.members).to contain_exactly(*hbx_enrollment_members)
        end

        it "should have correct plan year start on" do
          expect(plan_cost_decorator.plan_year_start_on).to eq plan_year.start_on
        end

        it "should have correct ages for everyone" do
          plan_cost_decorator.members.each do |member|
            expect(plan_cost_decorator.age_of(member)).to eq member.age_on_effective_date
          end
        end

        it "should have correct child indexes" do
          expect(hbx_enrollment_members.collect(){|member|plan_cost_decorator.child_index(member)}).to match_array([-1,-1,0,1,2,3])
        end

        it "should have correct member indexes" do
          expect(hbx_enrollment_members.collect(){|member|plan_cost_decorator.member_index(member)}).to match_array([0,1,2,3,4,5])
        end

        it "should have correct relationships" do
          expect(hbx_enrollment_members.collect(){|member|plan_cost_decorator.relationship_for(member)}).to match_array(%w[employee spouse child_under_26 child_under_26 child_under_26 child_under_26])
        end

        it "should have correct large family factors" do
          expect(hbx_enrollment_members.collect(){|member|plan_cost_decorator.large_family_factor(member)}).to match_array([1.0, 1.0, 1.0, 1.0, 1.0, 0.0])
        end

        it "should have correct employer contribution percent" do
          expect(plan_cost_decorator.employer_contribution_percent).to eq benefit_group.contribution_pct_as_int
        end

        it "should have correct total max employer contribution" do
          expect(plan_cost_decorator.total_max_employer_contribution).to eq benefit_group.over_one_dependents_max_amt
        end

        it "should have correct premiums" do
          expect(hbx_enrollment_members.collect(){|member| plan_cost_decorator.premium_for(member).round(2)}).to match_array(premiums)
        end

        it "should have correct employer contributions" do
          expect(hbx_enrollment_members.inject(0.00) {|acc, member| ((acc + plan_cost_decorator.employer_contribution_for(member)).round(2)) }).to eq plan_cost_decorator.total_employer_contribution.round(2)
        end

        it "should have correct employee costs" do
          expect(hbx_enrollment_members.collect(){ |member| plan_cost_decorator.employee_cost_for(member) }).to match_array(premiums.collect(){ |premium| premium * (100 - benefit_group.contribution_pct_as_int) / 100.0})
        end

        it "should have correct total premium" do
          expect(plan_cost_decorator.total_premium).to eq premiums.sum
        end

        it "should have correct total employer contribution" do
          expect(plan_cost_decorator.total_employer_contribution).to eq (premiums.sum * benefit_group.contribution_pct_as_int / 100.0)
        end

        it "should have correct total employee cost" do
          expect(plan_cost_decorator.total_employee_cost).to eq (premiums.sum * (100.0 - benefit_group.contribution_pct_as_int) / 100.0)
        end
      end

    end
  end
end
