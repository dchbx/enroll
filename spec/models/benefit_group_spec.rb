require 'rails_helper'

describe BenefitGroup, dbclean: :after_each do
  context "an employer profile with census_employees exists" do
    let!(:employer_profile) { FactoryGirl.create(:employer_profile)}
    let!(:census_employees) do
      [1,2].collect do
        FactoryGirl.create(:census_employee, employer_profile: employer_profile)
      end.sort_by(&:id)
    end
    context "and a plan year exists" do
      let(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_plan_year)}

      context "starting on 2/1/2015" do
        let(:start_plan_year) {Date.new(2015, 2, 1)}
        context "and a benefit_group_exists" do
          let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, effective_on_kind: "first_of_month", effective_on_offset: 30)}
          it "knows effective on for dates of hire" do
            year = 2015
            day = 15
            (0..11).each do |month_offset|
              date = (start_plan_year + 14.days) + month_offset.months
              expected_effective = (date + benefit_group.effective_on_offset.days).beginning_of_month.next_month
              expect(benefit_group.effective_on_for(date)).to eq expected_effective
            end
            date_of_hire = Date.new(2015, 1, 1)
            expected_effective = start_plan_year
            expect(benefit_group.effective_on_for(date_of_hire)).to eq expected_effective
            date_of_hire = Date.new(2015, 1, 15)
            expected_effective = Date.new(2015, 3, 1)
            expect(benefit_group.effective_on_for(date_of_hire)).to eq expected_effective
            date_of_hire = Date.new(2015, 1, 31)
            expected_effective = Date.new(2015, 4, 1)
            expect(benefit_group.effective_on_for(date_of_hire)).to eq expected_effective
          end
        end
      end

      context "starting on 1/1/xxxx" do
        let(:start_plan_year) {Date.new(2015, 1, 1)}
        context "and a benefit_group_exists" do
          let(:benefit_group) { FactoryGirl.create(:benefit_group, :invalid_employee_relationship_benefit, plan_year: plan_year, effective_on_kind: "first_of_month", effective_on_offset: 30)}

          it "is true" do
            expect(benefit_group.save).to be_truthy
          end
        end
      end

      context "starting on 4/1/2015" do
        let(:start_plan_year) {Date.new(2015, 4, 1)}
        context "and a benefit_group_exists" do
          let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, effective_on_kind: "first_of_month", effective_on_offset: 30)}
          it "knows effective on for dates of hire" do
            year = 2015
            day = 15
            (0..11).each do |month_offset|
              date = (start_plan_year + 0.days) + month_offset.months
              doh_with_offset = (date + benefit_group.effective_on_offset.days)
              expected_effective = doh_with_offset.day == 1 ? doh_with_offset : doh_with_offset.beginning_of_month.next_month
              expect(benefit_group.effective_on_for(date)).to eq expected_effective
            end
            date_of_hire = Date.new(2010, 01, 01)
            expected_effective = start_plan_year
            expect(benefit_group.effective_on_for(date_of_hire)).to eq expected_effective
          end
        end
      end
    end
  end
end

describe BenefitGroup, "instance methods" do
  let!(:benefit_group)            { FactoryGirl.build(:benefit_group) }
  let!(:plan_year)                { FactoryGirl.build(:plan_year, benefit_groups: [benefit_group], start_on: Date.new(2015,1,1)) }
  let!(:employer_profile)         { FactoryGirl.create(:employer_profile, plan_years: [plan_year]) }
  let!(:benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group) }
  let!(:census_employees) do
    [1,2].collect do
      FactoryGirl.create(:census_employee, employer_profile: employer_profile, benefit_group_assignments: [benefit_group_assignment] )
    end.sort_by(&:id)
  end

  context "" do
  end

  context "census_employees and benefit_group.census_employees" do
    let(:benefit_group_census_employees) {benefit_group.census_employees.sort_by(&:id)}

    it "should include the same census_employees" do
      expect(benefit_group_census_employees).to eq census_employees
    end
  end

  describe "should check if valid for census_employees" do
    let(:terminated_on_date) { Date.new(2015, 7, 31) }
    let(:hired_on_date) { Date.new(2015, 6, 1) }
    let(:census_employee) { CensusEmployee.new(:hired_on => hired_on_date, :employment_terminated_on => terminated_on_date) }

    context "given an invalid terminated and end date combo " do
       let(:terminated_on_date) { Date.new(2014, 1, 2) }

       it "is not assignable_to an employee fired before it starts" do
         expect(benefit_group.assignable_to?(census_employee)).to be_falsey
       end
     end

    context "given an invalid hired and start date combo" do
      let(:hired_on_date) { Date.new(2016, 6, 5) }

      it "is not assignable_to an employee hired after it ends" do
        expect(benefit_group.assignable_to?(census_employee)).to be_falsey
      end
    end

    it "should be valid if both dates fall inside plan year correctly" do
      expect(benefit_group.assignable_to?(census_employee)).to be_truthy
    end
  end

  it "should return the reference plan associated with this benefit group" do
    expect(benefit_group.reference_plan).to be_instance_of Plan
  end

  it "verifies the reference plan is included in the set of elected_plans" do
    expect(benefit_group.elected_plans).to include(benefit_group.reference_plan)
  end

  it "knows effective on for dates of hire" do
    year = 2015
    day = 15
    (1..12).each do |month|
      date = Date.new(year, month, day)
      expect(benefit_group.effective_on_for(date)).to eq date
    end
  end

  it "verifies each elected plan is a plan" do
    expect do
      benefit_group.elected_plans.each do |plan_id|
        expect(Plan.find(plan_id)).to be_instance_of Plan
      end
    end.not_to raise_exception
  end

  it "write attribute by employer_max_amt_in_cents" do
    benefit_group.employer_max_amt_in_cents = "100"
    expect(benefit_group.premium_in_dollars).to be 100.to_f
  end

  context "simple benefit list" do
    let(:benefit_list){benefit_group.simple_benefit_list(50,20,200)}

    it "should have six item" do
      expect(benefit_list.size).to eq BenefitGroup::PERSONAL_RELATIONSHIP_KINDS.size
    end

    it "should have same employer_max_amount" do
      expect(benefit_list.map(&:employer_max_amt)).to eq Array.new(5, 200)
    end

    it "should have different premium_pct" do
      expect(benefit_list.map(&:premium_pct)).to eq [50,20,20,20,50]
    end

    it "should have different offered" do
      expect(benefit_list.map(&:offered)).to eq [true, true, true, true, false]
    end
  end
end


describe BenefitGroup, type: :model do

  let(:title)                   { "Employee Perks" }
  let(:plan_year)               { FactoryGirl.build(:plan_year) }
  let(:reference_plan)          { FactoryGirl.build(:plan) }
  let(:plan_option_kind)        { "single_plan" }
  let(:effective_on_kind)       { "first_of_month" }
  let(:effective_on_offset)     { 30 }
  let(:terminate_on_kind)       { "end_of_month" }

  let(:effective_on_offset_default)   { 0 }
  let(:effective_on_kind_default)     { "first_of_month" }
  let(:terminate_on_kind_default)     { "end_of_month" }

  let(:elected_plans)                 { reference_plan.to_a }


  let(:relationship_benefits) do
    [
      RelationshipBenefit.new(offered: true, relationship: :employee, premium_pct: 100),
      RelationshipBenefit.new(offered: true, relationship: :spouse, premium_pct: 75),
      RelationshipBenefit.new(offered: true, relationship: :domestic_partner, premium_pct: 75),
      RelationshipBenefit.new(offered: true, relationship: :child_under_26, premium_pct: 50),
      RelationshipBenefit.new(offered: true, relationship: :disabled_child_26_and_over, premium_pct: 50),
      RelationshipBenefit.new(offered: false, relationship: :child_26_and_older, premium_pct: 0)
    ]
  end

  let(:valid_params) do
    {
        plan_year: plan_year,
        title: title,
        relationship_benefits: relationship_benefits,
        reference_plan: reference_plan,
        elected_plans: elected_plans,
        plan_option_kind: plan_option_kind,
        effective_on_kind: effective_on_kind,
        effective_on_offset: effective_on_offset,
        terminate_on_kind: terminate_on_kind,
    }
  end

  context "a new instance" do
    context "with no arguments" do
      let(:params) {{}}

      it "should be invalid" do
        expect(BenefitGroup.create(**params).valid?).to be_falsey
      end
    end

    context "with no reference_plan" do
      let(:params) {valid_params.except(:reference_plan)}

      it "should be invalid" do
        expect(BenefitGroup.create(**params).errors[:reference_plan_id].any?).to be_truthy
      end
    end

    context "with no elected_plans" do
      let(:params) {valid_params.except(:elected_plans)}

      it "should be invalid" do
        expect(BenefitGroup.create(**params).errors[:elected_plan_ids].any?).to be_truthy
      end
    end

    context "with no plan option kind" do
      let(:params) {valid_params.except(:plan_option_kind)}

      it "should be invalid" do
        expect(BenefitGroup.create(**params).errors[:plan_option_kind].any?).to be_truthy
      end
    end

    context "with no title" do
      let(:params) {valid_params.except(:title)}

      # it "should be invalid" do
      #   expect(BenefitGroup.create(**params).errors[:title].any?).to be_truthy
      # end

      # TODO - Remove default value?
      it "should initialize with default value" do
        expect(BenefitGroup.new(**params).title).to eq ""
      end
    end

    context "with no relationship_benefits" do
      let(:params) {valid_params.except(:relationship_benefits)}

      it "should be invalid" do
        expect(BenefitGroup.create(**params).errors[:relationship_benefits].any?).to be_truthy
      end
    end

    context "with no effective_on_offset" do
      let(:params) {valid_params.except(:effective_on_offset)}

      it "should initialize with default value" do
        expect(BenefitGroup.new(**params).effective_on_offset).to eq effective_on_offset_default
      end
    end

    context "with no effective_on_kind" do
      let(:params) {valid_params.except(:effective_on_kind)}

      it "should initialize with default value" do
        expect(BenefitGroup.new(**params).effective_on_kind).to eq effective_on_kind_default
      end
    end

    context "with no terminate_on_kind" do
      let(:params) {valid_params.except(:terminate_on_kind)}

      it "should initialize with default value" do
        expect(BenefitGroup.new(**params).terminate_on_kind).to eq terminate_on_kind_default
      end
    end

    context "with all valid parameters" do
      let(:params) {valid_params}
      let(:benefit_group)  { BenefitGroup.new(**params) }

      it "should save" do
        expect(benefit_group.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_benefit_group) do
          b = BenefitGroup.new(**params)
          b.save!
          b
        end

        it "should be findable" do
          expect(BenefitGroup.find(saved_benefit_group._id)).to eq saved_benefit_group
        end

        context "and termination effective on date is requested" do
          let(:three_days_after_oe_start_on)  { plan_year.open_enrollment_start_on + 3.days }
          let(:one_day_after_oe_end_on)       { plan_year.open_enrollment_end_on + 1.day }

          context "and termination is during open enrollment" do
            it "termination date should be start_on date" do
              expect(saved_benefit_group.termination_effective_on_for(three_days_after_oe_start_on)).to eq plan_year.start_on
            end

            it "termination date should be start_on date" do
              expect(saved_benefit_group.termination_effective_on_for(one_day_after_oe_end_on)).to eq plan_year.start_on
            end

          end

          context "and termination is outside open enrollment" do
            let(:one_day_before_start_on)   { plan_year.start_on - 1.day }
            let(:offset_period)             { 80 }
            let(:after_start_on)            { plan_year.start_on + offset_period.days }

            context "before start_on date" do
              it "termination date should be start_on date" do
                expect(saved_benefit_group.termination_effective_on_for(one_day_before_start_on)).to eq plan_year.start_on
              end
            end

            context "and termination is after start_on date" do
              it "termination date should be last day of month following supplied date" do
                expect(saved_benefit_group.termination_effective_on_for(after_start_on)).to eq after_start_on.end_of_month
              end

            end
          end
        end

      end
    end
  end

  context "and a reference plan is selected" do
    let(:params)                { valid_params }
    let(:benefit_group)         { BenefitGroup.new(**params) }
    let(:reference_plan_choice) { Plan.first }

    context "and the 'single plan' option is chosen" do
      before do
        benefit_group.plan_option_kind = "single_plan"
        benefit_group.reference_plan = reference_plan_choice
        benefit_group.elected_plans  = reference_plan_choice.to_a
      end

      it "elected plans should be the reference plan" do
        expect(benefit_group.elected_plans).to eq reference_plan_choice.to_a
      end

      it "the lowest cost plan should be reference plan" do
        expect(benefit_group.lowest_cost_plan).to eq reference_plan_choice
      end

      it "the highest cost plan should be reference plan" do
        expect(benefit_group.highest_cost_plan).to eq reference_plan_choice
      end

      context "and the elected plan is not the reference plan" do
        let(:elected_plan_choice)     { FactoryGirl.build(:plan) }

        before do
          benefit_group.plan_option_kind = :single_plan
          benefit_group.reference_plan = reference_plan_choice
          benefit_group.elected_plans = [elected_plan_choice]
        end

        it "should be invalid" do
          expect(benefit_group.valid?).to be_falsey
          expect(benefit_group.errors[:elected_plans].any?).to be_truthy
        end
      end
    end

    context "and the 'metal level' option is offered" do
      let(:reference_plan_choice)   { FactoryGirl.build(:plan) }
      let(:elected_plan_choice)     { FactoryGirl.build(:plan) }

      context "and elected plans are not all of the same metal level as reference plan" do
        before do
          benefit_group.plan_option_kind = :metal_level
          benefit_group.reference_plan = reference_plan_choice
          benefit_group.elected_plans = [elected_plan_choice]
        end

        it "should be invalid" do
          expect(benefit_group.valid?).to be_falsey
          expect(benefit_group.errors[:elected_plans].any?).to be_truthy
        end
      end
    end

    context "and the 'carrier plans' option is offered" do
      let(:organization)            { FactoryGirl.create(:organization) }
      let(:carrier_profile)         { FactoryGirl.create(:carrier_profile) }
      let(:carrier_profile_1)       { FactoryGirl.create(:carrier_profile, organization: organization) }
      let(:reference_plan_choice)   { FactoryGirl.create(:plan, :with_premium_tables, carrier_profile: carrier_profile) }
      let(:elected_plan_choice)     { FactoryGirl.create(:plan, :with_premium_tables, carrier_profile: carrier_profile_1) }
      let(:elected_plan_set) do
        plans = [1, 2, 3].collect do
          FactoryGirl.create(:plan, :with_premium_tables, carrier_profile: carrier_profile)
        end
        plans.concat([reference_plan_choice, elected_plan_choice])
        plans
      end

      context "and the reference plan is not in the elected plan set" do
        before do
          benefit_group.plan_option_kind = :single_carrier
          benefit_group.reference_plan = reference_plan_choice
          benefit_group.elected_plans = [elected_plan_choice]
        end

        it "should be invalid" do
          expect(benefit_group.valid?).to be_falsey
          expect(benefit_group.errors[:elected_plans].any?).to be_truthy
          expect(benefit_group.errors[:elected_plans].first).to match(/single carrier must include reference plan/)
        end
      end

      context "and elected plans are not all from the same carrier as reference plan" do
        before do
          benefit_group.plan_option_kind = :single_carrier
          benefit_group.reference_plan = reference_plan_choice
          benefit_group.elected_plans = elected_plan_set
        end

        it "should be invalid" do
          expect(benefit_group.valid?).to be_falsey
          expect(benefit_group.errors[:elected_plans].any?)
          .to be_truthy
          expect(benefit_group.errors[:elected_plans].first).to match(/not all from the same carrier as reference plan/)
        end
      end
    end
  end

  context "and relationship benefit values are specified" do
    let(:plan_year) { FactoryGirl.create(:plan_year) }
    let(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year) }

    context "and employer contribution for employee" do
      let(:minimum_contribution) { Settings.aca.shop_market.employer_contribution_percent_minimum }
      let(:invalid_minimum_contribution) { minimum_contribution - 1 }

      context "when the start_on of plan year is Jan 1" do
        before do
          benefit_group.plan_year.start_on = plan_year.start_on.at_beginning_of_year
        end

        it "should be valid when meeting the HBX minimum" do
          benefit_group.relationship_benefits.find_by(relationship: "employee").premium_pct = minimum_contribution
          expect(benefit_group.valid?).to be_truthy
          expect(benefit_group.errors[:relationship_benefits].any?).to be_falsey
        end

        it "should be valid when less than HBX minimum" do
          benefit_group.relationship_benefits.find_by(relationship: "employee").premium_pct = invalid_minimum_contribution
          expect(benefit_group.valid?).to be_truthy
          expect(benefit_group.errors[:relationship_benefits].any?).to be_falsey
        end
      end

      context "when the start_on of plan year is not Jan 1" do
        before do
          benefit_group.plan_year.start_on = (plan_year.start_on.at_beginning_of_year + 1.month)
        end

        it "should be valid when meeting the HBX minimum" do
          benefit_group.relationship_benefits.find_by(relationship: "employee").premium_pct = minimum_contribution
          expect(benefit_group.valid?).to be_truthy
          expect(benefit_group.errors[:relationship_benefits].any?).to be_falsey
        end

        it "should fail validation when less than HBX minimum" do
          benefit_group.relationship_benefits.find_by(relationship: "employee").premium_pct = invalid_minimum_contribution
          expect(benefit_group.valid?).to be_falsey
          expect(benefit_group.errors[:relationship_benefits].any?).to be_truthy
        end
      end
    end

    context "check offered for employee" do
      it "should valid when offered" do
        benefit_group.relationship_benefits.find_by(relationship: "employee").offered = true
        expect(benefit_group.valid?).to be_truthy
        expect(benefit_group.errors[:relationship_benefits].any?).to be_falsey
      end

      it "should fail when not offered" do
        benefit_group.relationship_benefits.find_by(relationship: "employee").offered = false
        expect(benefit_group.valid?).to be_falsey
        expect(benefit_group.errors[:relationship_benefits].any?).to be_truthy
      end
    end
  end

  describe BenefitGroup, dbclean: :after_each do

    context "contribution amount calculations" do

      let!(:employer_profile) { FactoryGirl.create(:employer_profile)}
      let(:start_plan_year) { TimeKeeper.date_of_record.end_of_month + 1.day }

      let!(:census_employees) do
        [1,2].collect do
          FactoryGirl.create(:census_employee, employer_profile: employer_profile)
        end.sort_by(&:id)
      end

      context "and a plan year exists" do

        let(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_plan_year)}

        context "when benefit_group not persisted in the database" do
          let!(:benefit_group) { FactoryGirl.build(:benefit_group, plan_year: plan_year, effective_on_kind: "first_of_month", effective_on_offset: 30)}
          it "should calculate contributions for all employees of the employer" do
            expect(benefit_group.targeted_census_employees.size).to eq 2
          end
        end

        context "when benefit_group saved" do
          let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, effective_on_kind: "first_of_month", effective_on_offset: 30)}
          it "should calculate contributions for employees assigned to benefit group" do
            expect(benefit_group.targeted_census_employees.size).to eq 0
          end
        end
      end
    end
  end

  describe BenefitGroup, dbclean: :after_each do
    context "effective_title_by_offset" do
      let(:benefit_group) { BenefitGroup.new }

      it "when effective_on_offset is 0" do
        benefit_group.effective_on_offset = 0
        expect(benefit_group.effective_title_by_offset).to eq "First of the month following or coinciding with date of hire"
      end

      it "when effective_on_offset is 30" do
        benefit_group.effective_on_offset = 30
        expect(benefit_group.effective_title_by_offset).to eq "First of the month following 30 days"
      end

      it "when effective_on_offset is 60" do
        benefit_group.effective_on_offset = 60
        expect(benefit_group.effective_title_by_offset).to eq "First of the month following 60 days"
      end
    end
  end


  describe BenefitGroup, dbclean: :after_each do
    context "effective_on_for" do

      let(:start_plan_year) { Date.new(2016, 1, 1) }
      let(:plan_year) { FactoryGirl.create(:plan_year, start_on: start_plan_year)}

      context "when employer picked 'Date of Hire'" do
        let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, effective_on_kind: "date_of_hire")}

        context "when doh is a past date" do
          let(:doh) { Date.new(2015, 8, 1)}

          it "should return plan year start on" do
            expect(benefit_group.effective_on_for(doh)).to eq start_plan_year
          end
        end

        context "when doh is a current date" do
          let(:doh) { Date.new(2016, 1, 1)}

          it "should return plan year start on" do
            expect(benefit_group.effective_on_for(doh)).to eq start_plan_year
          end
        end

        context "when doh is a future date" do
          let(:doh) { Date.new(2016, 1, 1)}

          it "should return date of hire" do
            expect(benefit_group.effective_on_for(doh)).to eq doh
          end
        end
      end

      context "when employer picked 'First of the month following or coinciding with date of hire'" do
        let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, effective_on_kind: "first_of_month", effective_on_offset: 0)}

        context "when doh is a past date first of month" do
          let(:doh) { Date.new(2015, 11, 1)}

          it "should return plan year start on" do
            expect(benefit_group.effective_on_for(doh)).to eq start_plan_year
          end
        end

        context "when doh is a past date other than first of month" do
          let(:doh) { Date.new(2015, 10, 28)}

          it "should return plan year start on" do
            expect(benefit_group.effective_on_for(doh)).to eq start_plan_year
          end
        end

        context "when doh is a future date first of month" do
          let(:doh) { Date.new(2016, 2, 1)}

          it "should return date of hire" do
            expect(benefit_group.effective_on_for(doh)).to eq doh
          end
        end

        context "when doh is a future date other than first of month" do
          let(:doh) { Date.new(2016, 2, 15)}

          it "should return first of next month from date of hire" do
            expect(benefit_group.effective_on_for(doh)).to eq doh.beginning_of_month.next_month
          end
        end
      end

      context "when employer picked 'First of the month following 30 days'" do
        let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, effective_on_kind: "first_of_month", effective_on_offset: 30)}

        context "when doh is a very old date" do
          let(:doh) { Date.new(2015, 8, 1)}

          it "should return plan year start on" do
            expect(benefit_group.effective_on_for(doh)).to eq start_plan_year
          end
        end

        context "when doh is less than a month from plan year start on" do
          let(:doh) { Date.new(2015, 12, 5) }

          it "should return eligible date as first of month following 30 days" do
            expect(benefit_group.effective_on_for(doh)).to eq Date.new(2016, 2, 1)
          end
        end

        context "when doh is a future date" do
          let(:doh) { Date.new(2016, 2, 1)}

          it "should return eligible date as first of month following 30 days" do
            expect(benefit_group.effective_on_for(doh)).to eq Date.new(2016, 4, 1)
            doh = Date.new(2016, 1, 10)
            expect(benefit_group.effective_on_for(doh)).to eq Date.new(2016, 3, 1)
            doh = Date.new(2016, 1, 2)
            expect(benefit_group.effective_on_for(doh)).to eq Date.new(2016, 2, 1)
          end
        end
      end

      context "when employer picked 'First of the month following 60 days'" do
        let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, effective_on_kind: "first_of_month", effective_on_offset: 60)}

        context "when doh is a very old date" do
          let(:doh) { Date.new(2015, 8, 10)}

          it "should return plan year start on" do
            expect(benefit_group.effective_on_for(doh)).to eq start_plan_year
          end
        end

        context "when doh is less than 60 days from plan year start on" do
          let(:doh) { Date.new(2015, 12, 5) }

          it "should return eligible date as first of month following 60 days" do
            expect(benefit_group.effective_on_for(doh)).to eq Date.new(2016, 3, 1)
          end
        end

        context "when doh is a future date" do
          let(:doh) { Date.new(2016, 2, 5)}

          it "should return eligible date as first of month following 60 days" do
            expect(benefit_group.effective_on_for(doh)).to eq Date.new(2016, 5, 1)
            doh = Date.new(2016, 3, 2)
            expect(benefit_group.effective_on_for(doh)).to eq Date.new(2016, 5, 1)
            doh = Date.new(2016, 3, 3)
            expect(benefit_group.effective_on_for(doh)).to eq Date.new(2016, 6, 1)
          end
        end
      end
    end

    context "renewing conversion employer" do
      let!(:employer_profile) { FactoryGirl.create(:employer_profile, profile_source: 'conversion', registered_on: Date.new(2016, 4, 1)) }
      let!(:off_exchange_planyear) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: Date.new(2015,7,1), end_on: Date.new(2016,6,30), open_enrollment_start_on: Date.new(2015, 5, 3), open_enrollment_end_on: Date.new(2015, 6, 10), aasm_state: 'active') }
      let!(:offexchange_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: off_exchange_planyear, effective_on_kind: "first_of_month", effective_on_offset: 0)}
      let!(:renewing_planyear) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: Date.new(2016,7,1), end_on: Date.new(2017,6,30), open_enrollment_start_on: Date.new(2016, 5, 3), open_enrollment_end_on: Date.new(2016, 6, 13), aasm_state: 'renewing_published') }
      let(:hired_on) { Date.new(2016, 5, 10) }

      context 'when plan is off-exchange plan year' do
        context '.valid_plan_year' do 
          it 'should return renewing plan year' do
            expect(offexchange_benefit_group.valid_plan_year).to eq renewing_planyear
          end
        end

        context '.date_of_hire_effective_on_for' do 
          it 'should return effection on as renewal plan year start' do
            expect(offexchange_benefit_group.date_of_hire_effective_on_for(hired_on)).to eq renewing_planyear.start_on
          end
        end

        context '.first_of_month_effective_on_for' do 
          it 'should return effective on as renewal plan year start' do
            expect(offexchange_benefit_group.first_of_month_effective_on_for(hired_on)).to eq renewing_planyear.start_on
          end
        end
      end

      context 'when plan year is not an off-exchange plan year' do

        before do 
          employer_profile.update_attributes(:registered_on => Date.new(2015,4,1))
        end

        context '.valid_plan_year' do 
          it 'should return plan year as is' do
            expect(offexchange_benefit_group.valid_plan_year).to eq off_exchange_planyear
          end 
        end

        context '.date_of_hire_effective_on_for' do 
          it 'should return date of hire as effective date' do
            expect(offexchange_benefit_group.date_of_hire_effective_on_for(hired_on)).to eq hired_on
          end
        end

        context '.first_of_month_effective_on_for' do 
          it 'should return first of next month as effective date' do
            expect(offexchange_benefit_group.first_of_month_effective_on_for(hired_on)).to eq hired_on.next_month.beginning_of_month
          end
        end
      end    
    end

  end
end
