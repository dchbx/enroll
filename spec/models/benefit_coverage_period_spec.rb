require 'rails_helper'

RSpec.describe BenefitCoveragePeriod, type: :model, dbclean: :after_each do

  let(:hbx_profile)               { FactoryBot.create(:hbx_profile) }
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
          let!(:silver_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
          let!(:bronze_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
          let(:benefit_package) { double }

          before :each do
            bronze_product.update_attributes(metal_level_kind: 'bronze')
            silver_product.update_attributes(metal_level_kind: 'silver')
          end

          context "and a silver plan is provided" do
            it "should set/get the assigned silver plan" do
              benefit_coverage_period.second_lowest_cost_silver_plan =  silver_product
              expect(benefit_coverage_period.second_lowest_cost_silver_plan).to eq silver_product
            end
          end

          context "and a non-silver plan is provided" do
            it "should raise an error" do
              expect{benefit_coverage_period.second_lowest_cost_silver_plan = bronze_product}.to raise_error(ArgumentError)
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
            # Need to revert the monthly_effective_date_deadline with following changes back on 5/1/2020
            # monthly_effective_date_deadline = HbxProfile::IndividualEnrollmentDueDayOfMonth
            monthly_effective_date_deadline = 15
            TimeKeeper.set_date_of_record_unprotected!(Date.new(2015, 9, monthly_effective_date_deadline))
          end

          it "should determine the earliest effective date is next month" do
            expect(benefit_coverage_period.earliest_effective_date).to eq Date.new(2015, 10, 1)
          end
        end

        context "and today is past the deadline to obtain benefits starting first of next month" do
          before do
            # Need to revert the monthly_effective_date_deadline with following changes back on 5/1/2020
            # monthly_effective_date_deadline = HbxProfile::IndividualEnrollmentDueDayOfMonth
            monthly_effective_date_deadline = 15
            TimeKeeper.set_date_of_record_unprotected!(Date.new(2015, 9, (monthly_effective_date_deadline + 1)))
          end

          it "should determine the earliest effective date is month after next" do
            # Need to revert the Date.new(2015, 10, 1) with following changes back on 5/1/2020
            expect(benefit_coverage_period.earliest_effective_date).to eq Date.new(2015, 11, 1)
            # expect(benefit_coverage_period.earliest_effective_date).to eq Date.new(2015, 10, 1)
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
    let(:benefit_coverage_period) { BenefitCoveragePeriod.new(start_on: Date.new(Time.current.year,1,1)) }
    let(:c1) {FactoryBot.create(:consumer_role)}
    let(:c2) {FactoryBot.create(:consumer_role)}
    let(:r1) {FactoryBot.create(:resident_role)}
    let(:r2) {FactoryBot.create(:resident_role)}
    let(:address) { FactoryBot.build(:address) }
    let(:family) { FactoryBot.build(:family, :with_primary_family_member_and_dependent)}
    let(:member1) do
      double(person: double(consumer_role: c1),hbx_enrollment: hbx_enrollment,family_member: family.family_members.where(is_primary_applicant: true).first, applicant_id: family.family_members[0].id,
             is_subscriber: true, home_address: address)
    end
    let(:member2) do
      double(person: double(consumer_role: c2),hbx_enrollment: hbx_enrollment,family_member: family.family_members.where(is_primary_applicant: false).first, applicant_id: family.family_members[1].id,
             is_subscriber: false, home_address:  address)
    end
    let(:hbx_enrollment){ HbxEnrollment.new(kind: "individual", product: plan1, effective_on: TimeKeeper.date_of_record, household: family.latest_household, enrollment_signature: true) }
    let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
    let(:plan1) { FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile: issuer_profile)}
    let(:plan2) { FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile: issuer_profile)}
    let(:plan3) { FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile: issuer_profile)}
    let(:plan4) { FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile: issuer_profile)}
    let(:benefit_package1) {double(benefit_ids: [plan1.id, plan2.id])}
    let(:benefit_package2) {double(benefit_ids: [plan3.id, plan4.id])}
    let(:benefit_packages)  { [benefit_package1, benefit_package2] }
    let(:rule) {double}

    before :each do
      TimeKeeper.set_date_of_record_unprotected!(Date.new(2015,10,20))
      Plan.delete_all
      allow(benefit_coverage_period).to receive(:benefit_packages).and_return [benefit_package1, benefit_package2]
      allow(InsuredEligibleForBenefitRule).to receive(:new).and_return rule
      plan1.update_attributes(benefit_market_kind: :aca_individual, metal_level_kind: 'gold', csr_variant_id: '01')
      plan2.update_attributes(benefit_market_kind: :aca_individual, metal_level_kind: 'gold', csr_variant_id: '01', application_period: {"min" => Date.new(2018,0o1,0o1), "max" => Date.new(2018,12,31)})
      plan3.update_attributes(benefit_market_kind: :aca_individual, metal_level_kind: 'gold', csr_variant_id: '01')
      plan4.update_attributes(benefit_market_kind: :aca_individual, metal_level_kind: 'gold', csr_variant_id: '01')
      allow(EnrollRegistry).to receive(:[]).with(:enroll_app).and_return(double(settings: double(item: 'DC Health Link')))
    end

    after do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    context 'single rating area model' do

      before :each do
        allow(EnrollRegistry).to receive(:[]).with(:service_area).and_return(double(settings: double(item: 'single')))
      end

      context 'when satisfied' do

        it 'should return plans' do
          allow(rule).to receive(:satisfied?).and_return [true, 'ok']
          elected_plans_by_enrollment_members = benefit_coverage_period.elected_plans_by_enrollment_members([member1, member2], 'health')
          expect(elected_plans_by_enrollment_members).to include(plan1)
          expect(elected_plans_by_enrollment_members).to include(plan3)
          expect(elected_plans_by_enrollment_members).not_to include(plan2)
        end
      end

      context 'when not satisfied' do

        it 'should not return any plans' do
          allow(rule).to receive(:satisfied?).and_return [false, 'ok']
          expect(benefit_coverage_period.elected_plans_by_enrollment_members([member1, member2], 'health')).to eq []
        end
      end
    end

    ['county', 'zipcode', 'mixed'].each do |rating_type|
      context "#{rating_type} based rating area model" do
        # let(:countyzip) { FactoryBot.create(:benefit_markets_locations_county_zip)}
        # let(:service_area) { FactoryBot.create(:benefit_markets_locations_service_area, covered_states: [], county_zip_ids: [countyzip.id])}
        # let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile: issuer_profile, service_area_id: service_area.id ) }

        let(:service_area) { ::BenefitMarkets::Locations::ServiceArea.all.first }
        before :each do
          allow(EnrollRegistry).to receive(:[]).with(:service_area).and_return(double(settings: double(item: rating_type)))
        end

        context 'when satisfied' do

          it 'should return plans' do
            allow(rule).to receive(:satisfied?).and_return [true, 'ok']
            elected_plans_by_enrollment_members = benefit_coverage_period.elected_plans_by_enrollment_members([member1, member2], 'health')
            expect(elected_plans_by_enrollment_members.length).to eq(3)
          end

          it 'should not include plans outside service area' do
            allow(rule).to receive(:satisfied?).and_return [true, 'ok']
            allow(::BenefitMarkets::Locations::ServiceArea).to receive(:service_areas_for).and_return([service_area])
            outside_plan = ::BenefitMarkets::Products::Product.where(:service_area_id.ne => service_area.id).first
            elected_plans_by_enrollment_members = benefit_coverage_period.elected_plans_by_enrollment_members([member1, member2], 'health')
            expect(elected_plans_by_enrollment_members).not_to include(outside_plan)
          end
        end

        context 'when not satisfied' do

          it 'should not return any plans' do
            allow(rule).to receive(:satisfied?).and_return [false, 'ok']
            expect(benefit_coverage_period.elected_plans_by_enrollment_members([member1, member2], 'health')).to eq []
          end
        end
      end
    end
  end
end
