require 'rails_helper'
require "#{Rails.root}/spec/shared_contexts/enrollment.rb"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe Enrollments::IndividualMarket::OpenEnrollmentBegin, type: :model do
    before do
      DatabaseCleaner.clean
    end

    context "Given a database of Families" do

      let!(:family) { FactoryBot.create(:individual_market_family) }
      let(:household) {FactoryBot.create(:household, family: family)}
      let!(:enrollment) {
                          FactoryBot.create(
                            :hbx_enrollment,
                            family: family,
                            household: household,
                            hbx_enrollment_members: [hbx_enrollment_member],
                            is_active: true,
                            aasm_state: 'coverage_enrolled',
                            changing: false,
                            effective_on: start_on,
                            coverage_kind: "health",
                            applied_aptc_amount: 10,
                            enrollment_kind: "open_enrollment",
                            kind: "individual",
                            submitted_at: start_on.prev_month,
                            plan_id: plan.id,
                      
                            )
                          }

      let(:hbx_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_family_member.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record.beginning_of_year)}
      let!(:update_family) {family.active_household.hbx_enrollments << [enrollment]}
      let(:hbx_profile)               { FactoryBot.create(:hbx_profile) }
      let(:benefit_sponsorship)       { hbx_profile.benefit_sponsorship }
      let(:title)                     { "My new enrollment period" }
      let(:service_market)            { "individual" }
      let(:start_on)                  { TimeKeeper.date_of_record.beginning_of_year }
      let(:end_on)                    { TimeKeeper.date_of_record.end_of_year }
      let(:open_enrollment_start_on)  { TimeKeeper.date_of_record.beginning_of_year - 2.months }
      let(:open_enrollment_end_on)    { TimeKeeper.date_of_record.beginning_of_year.end_of_month }

      let!(:valid_params){
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

      let(:params)                  { valid_params }
      let!(:benefit_coverage_period) { BenefitCoveragePeriod.new(**params) }

      let(:active_individual_health_plan)       { FactoryBot.create(:active_individual_health_plan) }
      let(:active_shop_health_plan)             { FactoryBot.create(:active_shop_health_plan) } 
      let(:active_individual_dental_plan)       { FactoryBot.create(:active_individual_dental_plan) } 
      let(:active_individual_catastophic_plan)  { FactoryBot.create(:active_individual_catastophic_plan) }
      let(:active_csr_87_plan)                  { FactoryBot.create(:active_csr_87_plan) } 
      let(:active_csr_00_plan)                  { FactoryBot.create(:active_csr_00_plan) }

      let(:renewal_individual_health_plan)       { FactoryBot.create(:renewal_individual_health_plan) }
      let(:renewal_shop_health_plan)             { FactoryBot.create(:renewal_shop_health_plan) } 
      let(:renewal_individual_dental_plan)       { FactoryBot.create(:renewal_individual_dental_plan) } 
      let(:renewal_individual_catastophic_plan)  { FactoryBot.create(:renewal_individual_catastophic_plan) }
      let(:renewal_csr_87_plan)                  { FactoryBot.create(:renewal_csr_87_plan) } 
      let(:renewal_csr_00_plan)                  { FactoryBot.create(:renewal_csr_00_plan) }
      let!(:plan) { FactoryBot.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'gold', active_year: TimeKeeper.date_of_record.year, hios_id: "11111111122302-01", csr_variant_id: "01")}
      let!(:subject) {Enrollments::IndividualMarket::OpenEnrollmentBegin.new}


      # let(:family_health_and_dental)      

      it "the collection should include ten or more Families" do
        # expect(Family.all.size).to be >= 10
      end

      it ".active_enrollment_from_family" do
        expect(subject.active_enrollment_from_family(enrollment).first).to eq enrollment
      end

      it "at least one Family with both active Individual Market Health and Dental plan Enrollments"
      it "at least one Family with an active 'Individual Market Health plan Enrollment only'"
      it "at least one Family with an active 'Assisted Individual Market Health plan Enrollment only'"
      it "at least one Family with an active 'Individual Market Catastrophic plan Enrollment only'"
      it "at least one Family with two active Individual Market Health plan Enrollments, one which is responsible person"
      it "at least one Family with active Individual and SHOP Market Health plan Enrollments"
      it "at least one Family with active Individual Market Dental and SHOP Market Health plan Enrollments"
      it "at least one Family with a terminated 'Individual Market Health plan Enrollment only'"
      it "at least one Family with a terminated 'Individual Market Dental plan Enrollment only'"
      it "at least one Family with a future terminated 'Individual Market Health plan Enrollment only'"
      it "at least one Family with a future terminated 'Individual Market Dental-only plan Enrollment'"


      context "and only Families eligible for enrollment auto renewal processing are selected from database" do

        it "the set should include Families with both active Individual Market Health and Dental plan Enrollments"
        it "the set should include Families with an active 'Individual Market Health plan Enrollment only'"
        it "the set should include Families with active Individual and SHOP Market Health plan Enrollments"
        it "the set should include Families with active Individual Market Dental and SHOP Market Health plan Enrollments"

        it "the set should not include Families with a terminated 'Individual Market Health plan Enrollment only'"
        it "the set should not include Families with a terminated 'Individual Market Dental plan Enrollment only'"
        it "the set should not include Families a future terminated 'Individual Market Health plan Enrollment only'"
        it "the set should not include Families a future terminated Individual Market Dental-only plan Enrollment"


        context "and the Family with both active Individual Market Health and Dental plan Enrollments is renewed" do
          it "should create a new Health enrollment"
          it "the new enrollment's health plan should be valid for the upcoming calendar year"
          it "the new enrollment's effective date should be Jan 1 of next calendar year"
          it "the new enrollment should include all the enrollees from the current plan year"
          it "the new enrollment should successfully calculate premium"

          it "should create a new Dental plan enrollment"
          it "the new enrollment's dental plan should be valid for the upcoming calendar year"
          it "the new enrollment's effective date should be Jan 1 of next calendar year"
          it "the new enrollment should include all the enrollees from the current plan year"
          it "the new enrollment should have a calculatable premium"

          context "and one child dependent is over age 26 on Jan 1" do
            it "the child should be member of the extended_family_coverage_household"
            it "the child should not be member of the immediate_family_coverage_household"
            it "the child should not be included in the new health enrollment group"
            it "the child should not be included in the new dental enrollment group"
          end

          context "and one child dependent is over age 26 Jan 1 and disabled" do
            it "the child should not be member of the extended_family_coverage_household"
            it "the child should be member of the immediate_family_coverage_household"
            it "the child should be included in the new health enrollment group"
            it "the child should be included in the new dental enrollment group"
          end
        end

        context "and the Family with an active 'Assisted Individual Market Health plan Enrollment only' is renewed" do

          context "and a financial eligibility determination is found" do
            context "and the determination end date is earlier than Jan 1 of the next calendar year" do
              it "the renewed enrollment should have $0 APTC for the new plan year"

              context "and the renewed enrollment is a silver plan" do
                it "the renewed plan should not have a CSR variant"
              end
            end

            context "and the financial assistance redetermination has no end date" do
              it "the renewed enrollment should have the same APTC percentage as the current enrollment"

              context "and the renewed enrollment is a silver plan" do
                it "the renewed plan should not have the CSR variant from the financial redetermination"
              end
            end
          end
        end

        context "and the Family with an active 'Individual Market Catastrophic plan Enrollment only' is renewed" do

          context "and none of the enrollment members are over age 30 on Jan 1" do
            it "the new enrollment should have a comparable Catastrophic plan"
          end

          context "and at least one of the enrollment members are over age 30 on Jan 1" do
            it "should renew enrollment into a mapped Bronze plan??"
          end
        end

        context "and the Family with two active Individual Market Health plan Enrollments, one which is responsible person is renewed" do
          it "should produce a new standard enrollment"
          it "should produce a new responsible person enrollment"
        end

        context "and the Family with active Individual and SHOP Market Health plan Enrollments" do
          it "should produce a new Individual health enrollment"
          it "should not produce a new SHOP health enrollment"
        end

        context "and the Family with active Individual Market Dental and SHOP Market Health plan Enrollments" do
          it "should produce a new Individual dental enrollment"
          it "should not produce a new SHOP health enrollment"
        end

        it ".can_renew_enrollment?" do
          value = subject.can_renew_enrollment?(enrollment, family, benefit_coverage_period)
          expect(value).to eq false
        end
      end
    end

    context "Today is 30 days prior to the first day of the Annual Open Enrollment period for the HBX Individual Market" do
      it "should generate and transmit renewal notices"
    end

    context "Today is the first day of the Annual Open Enrollment period for the HBX Individual Market" do
      context "and health and dental plans and rates for the new calendar year are loaded" do
        context "and comparable plan mapping from this calendar year to the next calendar year is present" do
          context "and Assisted QHP Families have finanancial eligibility redetermined for the next calendar year" do
          end
        end
      end
    end

    describe "To test passive renewals with only ivl health plans" do
      include_context "setup families enrollments"
      let!(:subject) {Enrollments::IndividualMarket::OpenEnrollmentBegin.new}

      context "Given a database of Families" do

        context "when OE script is executed" do

          before do
            hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(renewal_calender_date.beginning_of_year)}.update_attributes!(slcsp_id: renewal_csr_87_plan.id)
            hbx_profile.reload
            renewal_individual_health_plan.reload
            active_individual_health_plan.reload
            family_assisted.active_household.reload
            allow(Caches::PlanDetails).to receive(:lookup_rate) {|id, start, age| age * 1.0}
          end

          it "should generate renewal enrollment for assisted family" do
            invoke_oe_script
            family_assisted.active_household.reload
            enrollments = family_assisted.active_household.hbx_enrollments
            expect(enrollments.size).to eq 2
            expect(enrollments[1].applied_aptc_amount.to_f).to eq (enrollments[1].total_premium * enrollments[1].plan.ehb).round(2)
          end
        end
      end
    end

    after(:all) do
      path = "#{Rails.root}/pids/"
      if Dir.exists?(path)
        FileUtils.rm_rf(path)
      end
    end
  end
end


private

def invoke_oe_script
  field_names =
      ["Icnumber", "Ssn", "Subscriber", "Member", "Firstname", "Lastname", "Dob",
       "#{renewal_calender_year - 1.year} Applied", "#{renewal_calender_year - 1.year} Max", "Unadjustedapplied", "Applied Pct",
       "#{renewal_calender_year} Aptc", "#{renewal_calender_year} Applied", "#{renewal_calender_year} Csr", "Error Msg"]
  Dir.mkdir("pids") unless File.exists?("pids")
  file_name = "#{Rails.root}/pids/2018_FA_Renewals.csv"

  CSV.open(file_name, "w") do |csv|
    csv << field_names
    person = family_assisted.primary_family_member.person
    csv << ["", person.ssn, person.hbx_id, person.hbx_id, person.first_name, person.last_name, person.dob, 100, 200, "", 0, 400, 150, 73]
  end

  oe_begin = Enrollments::IndividualMarket::OpenEnrollmentBegin.new
  oe_begin.process_renewals
end