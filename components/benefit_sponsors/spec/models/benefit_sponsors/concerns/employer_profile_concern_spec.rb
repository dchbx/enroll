require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module BenefitSponsors
  RSpec.describe Concerns::EmployerProfileConcern, type: :model, dbclean: :around_each do
    describe "#billing_benefit_application" do
      let(:organization) { FactoryBot.build(:benefit_sponsors_organizations_general_organization,
        :with_site,
        :with_aca_shop_cca_employer_profile_initial_application
      )}

      let(:profile) { organization.employer_profile }
      let(:benefit_sponsorship) { organization.active_benefit_sponsorship }
      let(:application) { benefit_sponsorship.current_benefit_application }

      context "when billing date is given" do
        it "should return application and given billing date if given date covers benefit_application effective period" do
          date = application.start_on
          expect(profile.billing_benefit_application(date)).to eq [application, date]
        end

        it "should return nil and given billing date if given date not covers benefit_application effective period" do
          date = application.start_on - 1.month
          expect(profile.billing_benefit_application(date)).to eq [nil, date]
        end

        it "should return nil and given billing date if given date covers canceled benefit_application effective period " do
          application.update_attributes!(aasm_state: :canceled)
          date = application.start_on
          expect(profile.billing_benefit_application(date)).to eq [nil, date]
        end
      end

      context "when billing date is blank" do
        context "For initial employer" do
          it "should return initial published application effective date & initial start on date" do
            application
            expect(profile.billing_benefit_application).to eq [application, TimeKeeper.date_of_record.next_month]
          end
        end

        context "For renewal employer" do
          include_context "setup benefit market with market catalogs and product packages"
          include_context "setup renewal application"

          let(:renewal_state)           { :enrollment_open }
          let(:renewal_effective_date)  { TimeKeeper.date_of_record.beginning_of_month }
          let(:current_effective_date)  { renewal_effective_date.prev_year }
          let(:profile) { abc_profile }

          it "should return renewal published application effective date & renewal start on date" do
            expect(profile.billing_benefit_application).to eq [renewal_application, TimeKeeper.date_of_record.next_month]
          end

          it "should return renewal canceled application effective date & renewal start on date" do
            renewal_application.update_attributes!(aasm_state: :canceled)
            expect(profile.billing_benefit_application).to eq [nil, nil]
          end
        end
      end
    end

    describe 'active_ga_legal_name' do
      include_context 'set up broker agency profile for BQT, by using configuration settings'

      let(:employer_profile) {plan_design_organization_with_assigned_ga.employer_profile}
      let!(:update_plan_design) {plan_design_organization_with_assigned_ga.update_attributes!(has_active_broker_relationship: true)}
      let(:ga_legal_name) {plan_design_organization_with_assigned_ga.general_agency_profile.legal_name.to_s}
      let(:site)            { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:abc_profile)    { organization.employer_profile }

      it 'should return legal name when GA account is assigned' do
        expect(employer_profile.active_ga_legal_name).to eq ga_legal_name
      end

      it 'should return nil when GA account is not assigned' do
        expect(abc_profile.active_ga_legal_name).to be nil
      end
    end

    describe 'terminate_roster_enrollments',  dbclean: :around_each do
      let!(:site)                  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let!(:rating_area)           { FactoryBot.create_default :benefit_markets_locations_rating_area }
      let!(:service_area)          { FactoryBot.create_default :benefit_markets_locations_service_area }
      let!(:rating_area2)           { FactoryBot.create_default :benefit_markets_locations_rating_area, active_year: TimeKeeper.date_of_record.prev_year.year }
      let!(:service_area2)          { FactoryBot.create_default :benefit_markets_locations_service_area, active_year: TimeKeeper.date_of_record.prev_year.year }
      let(:benefit_sponsorship) do
        create(
            :benefit_sponsors_benefit_sponsorship,
            :with_organization_cca_profile,
            :with_renewal_benefit_application,
            :with_rating_area,
            :with_service_areas,
            initial_application_state: :active,
            renewal_application_state: :enrollment_open,
            default_effective_period: ((TimeKeeper.date_of_record.next_month.end_of_month + 1.day)..(TimeKeeper.date_of_record.next_month.end_of_month + 1.year)),
            site: site,
            aasm_state: :active
        )
      end

      let(:employer_profile) { benefit_sponsorship.profile }
      let(:active_benefit_package) { employer_profile.active_benefit_application.benefit_packages.first }
      let(:active_sponsored_benefit) {  employer_profile.active_benefit_application.benefit_packages.first.sponsored_benefits.first}
      let(:renewal_benefit_package) { employer_profile.renewal_benefit_application.benefit_packages.first }
      let(:renewal_sponsored_benefit) {  employer_profile.renewal_benefit_application.benefit_packages.first.sponsored_benefits.first}
      let!(:person) {FactoryBot.create(:person)}
      let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
      let!(:employee_role) { FactoryBot.create(:employee_role, person: person, census_employee: census_employee, employer_profile: benefit_sponsorship.profile) }
      let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
      let!(:active_enrollment) { FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                                                   household: family.latest_household,
                                                   coverage_kind: "health",
                                                   family: family,
                                                   effective_on: employer_profile.active_benefit_application.start_on,
                                                   enrollment_kind: "open_enrollment",
                                                   kind: "employer_sponsored",
                                                   aasm_state: 'coverage_selected',
                                                   benefit_sponsorship_id: benefit_sponsorship.id,
                                                   sponsored_benefit_package_id: active_benefit_package.id,
                                                   sponsored_benefit_id: active_sponsored_benefit.id,
                                                   employee_role_id: employee_role.id) }
      let!(:renewal_enrollment) { FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                                                    household: family.latest_household,
                                                    coverage_kind: "health",
                                                    family: family,
                                                    effective_on: employer_profile.renewal_benefit_application.start_on,
                                                    enrollment_kind: "open_enrollment",
                                                    kind: "employer_sponsored",
                                                    aasm_state: 'auto_renewing',
                                                    benefit_sponsorship_id: benefit_sponsorship.id,
                                                    sponsored_benefit_package_id: renewal_benefit_package.id,
                                                    employee_role_id: employee_role.id,
                                                    sponsored_benefit_id: renewal_sponsored_benefit.id) }
      before do
        census_employee.update_attributes({employee_role_id: employee_role.id})
         args = {"employer_profile_id" => employer_profile.id.to_s, "termination_reason" => "non_payment", "termination_date" => employer_profile.active_benefit_application.end_on.strftime("%m/%d/%Y"), "transmit_xml" => true}
        employer_profile.terminate_roster_enrollments(args)
      end


      it "should terminate active enrollment" do
        active_enrollment.reload
        expect(active_enrollment.aasm_state).to eq('coverage_termination_pending')
        expect(active_enrollment.terminate_reason).to eq('non_payment')
        expect(active_enrollment.terminated_on).to eq employer_profile.active_benefit_application.end_on
      end

      it "should cancel renewal enrollment" do
        renewal_enrollment.reload
        expect(renewal_enrollment.aasm_state).to eq('coverage_canceled')
        expect(renewal_enrollment.terminate_reason).to eq nil
        expect(active_enrollment.terminated_on).to eq nil
      end
    end

    describe '.future_active_reinstated_benefit_application', :dbclean => :after_each do

      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

      let(:benefit_application) { initial_application }

      it 'should return future_active_reinstated_benefit_application' do
        period = benefit_application.effective_period.min + 1.year..(benefit_application.effective_period.max + 1.year)
        benefit_application.update_attributes!(reinstated_id: BSON::ObjectId.new, aasm_state: :active, effective_period: period)
        expect(abc_profile.future_active_reinstated_benefit_application).to eq benefit_application
      end

      it 'should return nil if no reinstated enrollment present' do
        expect(abc_profile.future_active_reinstated_benefit_application).to eq nil
      end
    end
  end
end
