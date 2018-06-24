require 'rails_helper'

RSpec.describe BenefitCoveragePeriod, type: :model, dbclean: :after_each do

  let(:hbx_profile)               { FactoryGirl.create(:hbx_profile) }
  let(:benefit_sponsorship)       { hbx_profile.benefit_sponsorship }
  let(:title)                     { "My new enrollment period" }
  let(:service_market)            { "individual" }
  let(:start_on)                  { Date.new(2015,10,1).beginning_of_year }
  let(:end_on)                    { Date.new(2015,10,1).end_of_year }
  let(:open_enrollment_start_on)  { Date.new(2015,10,1).beginning_of_year - 2.months }
  let(:open_enrollment_end_on)    { Date.new(2015,10,1).beginning_of_year.end_of_month }

  let(:valid_params){
      {
        title: title,
        benefit_sponsorship: benefit_sponsorship,
        service_market: service_market,
        start_on: start_on,
        end_on: end_on,
        open_enrollment_start_on: open_enrollment_start_on,
        open_enrollment_end_on: open_enrollment_end_on
      }
    }

  context "a new instance" do

    after :all do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(BenefitCoveragePeriod.create(**params).valid?).to be_falsey
      end
    end

    context "missing any required argument" do
      before :each do
        subject.valid?
      end

      [:service_market, :start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on].each do |property|
        it "should require #{property}" do
          expect(subject).to have_errors_on(property)
        end
      end
    end

    context "with all required attributes" do
      let(:params)                  { valid_params }
      let(:benefit_coverage_period) { BenefitCoveragePeriod.new(**params) }

      it "should be valid" do
        expect(benefit_coverage_period.valid?).to be_truthy
      end

      it "should save" do
        expect(benefit_coverage_period.save).to be_truthy
      end

      context "and it is saved" do
        before { benefit_coverage_period.save }

        it "should be findable by ID" do
          expect(BenefitCoveragePeriod.find(benefit_coverage_period.id)).to eq benefit_coverage_period
        end

        it "should be findable by date" do
          expect(BenefitCoveragePeriod.find_by_date(benefit_coverage_period.start_on + 25.days)).to eq benefit_coverage_period
        end

        context "and a second lowest cost silver plan is specified" do
          let(:silver_plan) { FactoryGirl.create(:plan, metal_level: "silver") }
          let(:bronze_plan) { FactoryGirl.create(:plan, metal_level: "bronze") }
          let(:benefit_package) { double }

          context "and a silver plan is provided" do
            it "should set/get the assigned silver plan" do
              expect(benefit_coverage_period.second_lowest_cost_silver_plan = silver_plan).to eq silver_plan
              expect(benefit_coverage_period.second_lowest_cost_silver_plan).to eq silver_plan
            end
          end

          context "and a non-silver plan is provided" do
            it "should raise an error" do
              expect{benefit_coverage_period.second_lowest_cost_silver_plan = bronze_plan}.to raise_error(ArgumentError)
            end
          end

          context "and a non plan object is passed" do
            it "should raise an error" do
              expect{benefit_coverage_period.second_lowest_cost_silver_plan = benefit_package}.to raise_error(ArgumentError)
            end
          end

        end

        context "and open enrollment dates are queried" do
          it "should determine dates that are within open enrollment" do
            expect(benefit_coverage_period.open_enrollment_contains?(open_enrollment_start_on)).to be_truthy
            expect(benefit_coverage_period.open_enrollment_contains?(open_enrollment_end_on)).to be_truthy
          end

          it "should determine dates that are not within open enrollment" do
            expect(benefit_coverage_period.open_enrollment_contains?(open_enrollment_start_on - 1.day)).to be_falsey
            expect(benefit_coverage_period.open_enrollment_contains?(open_enrollment_end_on + 1.day)).to be_falsey
          end
        end

        context "and today is the last day to obtain benefits starting first of next month" do
          before do
            monthly_effective_date_deadline = HbxProfile::IndividualEnrollmentDueDayOfMonth
            TimeKeeper.set_date_of_record_unprotected!(Date.new(2015, 9, monthly_effective_date_deadline))
          end

          it "should determine the earliest effective date is next month" do
            expect(benefit_coverage_period.earliest_effective_date).to eq Date.new(2015, 10, 1)
          end
        end

        context "and today is past the deadline to obtain benefits starting first of next month" do
          before do
            monthly_effective_date_deadline = HbxProfile::IndividualEnrollmentDueDayOfMonth
            TimeKeeper.set_date_of_record_unprotected!(Date.new(2015, 9, (monthly_effective_date_deadline + 1)))
          end

          it "should determine the earliest effective date is month after next" do
            expect(benefit_coverage_period.earliest_effective_date).to eq Date.new(2015, 11, 1)
          end
        end

        context "and termination effective on date is requested" do

          # No termination if coverage not yet started
          let(:five_days_after_start_on)          { start_on + 5.days }
          let(:twenty_days_after_start_on)        { start_on + 20.days }

          context "and termination is during open enrollment" do

            context "and termination is after start_on date" do
              context "and before monthly enrollment deadline" do
                it "termination date should be last day of month following start_on date" do
                  expect(benefit_coverage_period.termination_effective_on_for(five_days_after_start_on)).to eq five_days_after_start_on
                end
              end

              context "and after monthly enrollment deadline" do
                it "termination date should be last day of next month following start_on date" do
                  expect(benefit_coverage_period.termination_effective_on_for(twenty_days_after_start_on)).to eq twenty_days_after_start_on
                end
              end
            end
          end

          context "and termination is outside open enrollment" do
            let(:compare_date)                  { (benefit_coverage_period.start_on + 3.months).beginning_of_month }

            before :each do
              TimeKeeper.set_date_of_record_unprotected!(compare_date)
            end

            it "termination date should be set to today if selected date is today " do
              expect(benefit_coverage_period.termination_effective_on_for(TimeKeeper.date_of_record)).to eq(TimeKeeper.date_of_record)
            end

            it "termination date should be set to the date selected if selected date is greater than today" do
              expect(benefit_coverage_period.termination_effective_on_for(TimeKeeper.date_of_record+7.day)).to eq(TimeKeeper.date_of_record+7.day)
            end

            context "and the effective date would " do               

              it "termination date should be set to end_on date" do
                expect(benefit_coverage_period.termination_effective_on_for(TimeKeeper.date_of_record.next_year)).to eq benefit_coverage_period.end_on
              end

            end
          end

        end
      end
    end
  end

  context "elected_plans_by_enrollment_members", dbclean: :before_each do
    let(:benefit_coverage_period) { BenefitCoveragePeriod.new(start_on: (TimeKeeper.date_of_record - 2.months).to_date) }
    let(:c1) {FactoryGirl.create(:consumer_role)}
    let(:c2) {FactoryGirl.create(:consumer_role)}
    let(:r1) {FactoryGirl.create(:resident_role)}
    let(:r2) {FactoryGirl.create(:resident_role)}
    let(:family) { FactoryGirl.build(:family, :with_primary_family_member_and_dependent)}
    let(:member1) {double(person: double(consumer_role: c1),hbx_enrollment: hbx_enrollment,family_member:family.family_members.where(is_primary_applicant: true).first)}
    let(:member2) {double(person: double(consumer_role: c2),hbx_enrollment: hbx_enrollment,family_member: family.family_members.where(is_primary_applicant: false).first)}
    let(:hbx_enrollment){ HbxEnrollment.new(kind: "individual", plan: plan1, effective_on: TimeKeeper.date_of_record, household: family.latest_household, enrollment_signature: true) }
    let(:plan1) { FactoryGirl.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'gold', csr_variant_id: '01', active_year: TimeKeeper.date_of_record.year, hios_id: "11111111122302-01") }
    let(:plan2) { FactoryGirl.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'gold', csr_variant_id: '01', active_year: TimeKeeper.date_of_record.year - 1, hios_id: "11111111122303-01") }
    let(:plan3) { FactoryGirl.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'gold', csr_variant_id: '01', active_year: TimeKeeper.date_of_record.year, hios_id: "11111111122304-01") }
    let(:plan4) { FactoryGirl.create(:plan, market: 'individual', active_year: TimeKeeper.date_of_record.year, hios_id: "11111111122305-02") }
    let(:benefit_package1) {double(benefit_ids: [plan1.id, plan2.id])}
    let(:benefit_package2) {double(benefit_ids: [plan3.id, plan4.id])}
    let(:benefit_packages)  { [benefit_package1, benefit_package2] }
    let(:rule) {double}

    before :each do
      TimeKeeper.set_date_of_record_unprotected!(Date.new(2015,10,20))
      Plan.delete_all
      allow(benefit_coverage_period).to receive(:benefit_packages).and_return [benefit_package1, benefit_package2]
      allow(InsuredEligibleForBenefitRule).to receive(:new).and_return rule
    end

    after do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    it "when satisfied" do
      allow(rule).to receive(:satisfied?).and_return [true, 'ok']
      plans = [plan1, plan3]
      elected_plans_by_enrollment_members = benefit_coverage_period.elected_plans_by_enrollment_members([member1, member2], 'health')
      expect(elected_plans_by_enrollment_members).to include(plan1)
      expect(elected_plans_by_enrollment_members).to include(plan3)
      expect(elected_plans_by_enrollment_members).not_to include(plan2)
    end

    it "when not satisfied" do
      allow(rule).to receive(:satisfied?).and_return [false, 'ok']
      plans = []
      expect(benefit_coverage_period.elected_plans_by_enrollment_members([member1, member2], 'health')).to eq plans
    end
  end
end
