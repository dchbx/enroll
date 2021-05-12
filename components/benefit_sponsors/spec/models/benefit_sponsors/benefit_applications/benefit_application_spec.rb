# frozen_string_literal: true

require 'rails_helper'
require File.join(File.dirname(__FILE__), "..", "..", "..", "support/benefit_sponsors_site_spec_helpers")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

class ApplicationHelperModStubber
  extend ::BenefitSponsors::Employers::EmployerHelper
end

#rubocop:disable Metrics/ModuleLength
#create benefit app with all params
module BenefitSponsors
  unless EnrollRegistry.feature_enabled?(:aca_shop_market) || EnrollRegistry.feature_enabled?(:fehb_market)
    RSpec.describe BenefitApplications::BenefitApplication, type: :model, :dbclean => :after_each, :if => ::EnrollRegistry[:aca_shop_market].enabled? do
      let(:site) { ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market }
      let(:benefit_market)          { site.benefit_markets.first }
      let(:employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{site.site_key}_employer_profile".to_sym, site: site) }
      let(:employer_profile_1)        { employer_organization.employer_profile }
      let(:benefit_sponsorship) do
        sponsorship_1 = employer_profile_1.add_benefit_sponsorship
        sponsorship_1.save
        sponsorship_1
      end
      let(:benefit_sponsor_catalog) { FactoryBot.create(:benefit_markets_benefit_sponsor_catalog, service_areas: [service_area]) }

      let(:rating_area)  { create_default(:benefit_markets_locations_rating_area) }
      let!(:rating_area2) {FactoryBot.create(:benefit_markets_locations_rating_area, active_year: TimeKeeper.date_of_record.next_year.year)}
      let(:service_area) { create_default(:benefit_markets_locations_service_area) }
      let(:sic_code)      { "001" }

      let(:effective_period_start_on) { TimeKeeper.date_of_record.beginning_of_month + 2.months }
      let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
      let(:effective_period)          { effective_period_start_on..effective_period_end_on }

      let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
      let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }
      let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

      let(:application_period_prev_year)        { (Date.new(effective_period_start_on.prev_year.year, 1, 1))..(Date.new(effective_period_start_on.prev_year.year, 12, 31)) }
      let(:application_period_next_year)        { (Date.new(effective_period_start_on.next_year.year, 1, 1))..(Date.new(effective_period_start_on.next_year.year, 12, 31)) }
      let!(:issuer_profile)  { FactoryBot.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}
      let!(:benefit_market_catalog_next_year)   { FactoryBot.create(:benefit_markets_benefit_market_catalog, :with_product_packages, issuer_profile: issuer_profile, benefit_market: benefit_market, application_period: application_period_next_year) }
      let!(:benefit_market_catalog_prev_year)   { FactoryBot.create(:benefit_markets_benefit_market_catalog, :with_product_packages, issuer_profile: issuer_profile, benefit_market: benefit_market, application_period: application_period_prev_year) }

      let(:params) do
        {
          effective_period: effective_period,
          open_enrollment_period: open_enrollment_period,
          benefit_sponsor_catalog: benefit_sponsor_catalog
        }
      end

      let(:valid_params) do
        {
          effective_period: effective_period,
          open_enrollment_period: open_enrollment_period,
          benefit_sponsor_catalog: benefit_sponsor_catalog,
          recorded_rating_area_id: rating_area.id,
          recorded_service_area_ids: [service_area.id],
          recorded_sic_code: sic_code
        }
      end

      describe "A new model instance" do
        it { is_expected.to be_mongoid_document }
        it { is_expected.to have_fields(:effective_period, :open_enrollment_period, :terminated_on)}
        it { is_expected.to have_field(:expiration_date).of_type(Date)}
        it { is_expected.to have_field(:aasm_state).of_type(Symbol).with_default_value_of(:draft)}
        it { is_expected.to have_field(:fte_count).of_type(Integer).with_default_value_of(0)}
        it { is_expected.to have_field(:pte_count).of_type(Integer).with_default_value_of(0)}
        it { is_expected.to have_field(:msp_count).of_type(Integer).with_default_value_of(0)}
        it { is_expected.to embed_many(:benefit_packages)}

        context "with no arguments" do
          subject { described_class.new }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
          end
        end

        context "with no effective_period" do
          subject { described_class.new(params.except(:effective_period)) }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:effective_period].first).to match(/can't be blank/)
          end
        end

        context "with no open_enrollment_period" do
          subject { described_class.new(params.except(:open_enrollment_period)) }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:open_enrollment_period].first).to match(/can't be blank/)
          end
        end

        context "with no recorded_service_areas" do
          subject { described_class.new(params.except(:recorded_service_areas)) }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:recorded_service_areas].first).to match(/can't be blank/)
          end
        end

        context "with no recorded_rating_area" do
          subject { described_class.new(params.except(:recorded_rating_area)) }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:recorded_rating_area].first).to match(/can't be blank/)
          end
        end

        if ApplicationHelperModStubber.display_sic_field_for_employer?
          context 'with no recorded_sic_code' do
            subject { described_class.new(params.except(:recorded_sic_code)) }

            it 'should not be valid' do
              subject.validate
              expect(subject).to_not be_valid
              expect(subject.errors[:recorded_sic_code].first).to match(/can't be blank/)
            end
          end
        end

        context "with all required arguments" do
          subject {described_class.new(valid_params) }

          before do
            subject.benefit_sponsorship = benefit_sponsorship
            benefit_sponsorship.save!
          end

          it "should be valid" do
            subject.validate
            expect(subject).to be_valid
          end

          context "and it is saved" do

            it "should save" do
              expect(subject.save).to eq true
            end

            context "it should be findable" do
              before { subject.save! }
              it "should return the instance" do
                expect(described_class.find(subject.id.to_s)).to eq subject
              end
            end
          end
        end
      end

      describe "Extending an open_enrollment_period", :dbclean => :after_each do
        let(:employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
        let(:benefit_sponsorship)     { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new(profile: employer_organization.employer_profile) }
        let(:benefit_application)     { described_class.new(valid_params) }

        before do
          benefit_application.benefit_sponsorship = benefit_sponsorship
          benefit_application.save!
        end

        context "and the application can transition to open enrollment state" do
          let(:valid_open_enrollment_transition_state)    { :approved }

          before { benefit_application.aasm_state = valid_open_enrollment_transition_state }

          it "transition into open enrollment should be valid" do
            expect(benefit_application.may_begin_open_enrollment?).to eq true
          end

          context "and the new end date is later than effective_period start" do
            let(:late_open_enrollment_end_date)  { effective_period.min + 1.day }

            before do
              benefit_application.extend_open_enrollment_period(late_open_enrollment_end_date)
            end

            it "should not change the open_enrollment_period" do
              expect(benefit_application.open_enrollment_end_on).to eq open_enrollment_period_end_on
            end

            it "should not change the application state" do
              expect(benefit_application.aasm_state).to eq valid_open_enrollment_transition_state
            end
          end

          context "and the new end date is in the past" do
            let(:past_date) { open_enrollment_period_end_on - 1.day }

            before do
              TimeKeeper.set_date_of_record_unprotected!(open_enrollment_period_end_on)
              benefit_application.extend_open_enrollment_period(past_date)
            end

            after { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

            it "should be able to transition into open enrollment" do
              expect(benefit_application.may_begin_open_enrollment?).to eq true
            end

            it "should not change the open_enrollment_period" do
              expect(benefit_application.open_enrollment_end_on).to eq open_enrollment_period_end_on
            end

            it "should not change the application state" do
              expect(benefit_application.aasm_state).to eq valid_open_enrollment_transition_state
            end
          end

          context "and the new end date is valid" do
            let(:valid_date)  { effective_period_start_on - 1.day }

            before do
              benefit_application.extend_open_enrollment_period(valid_date)
            end

            it "should change the open_enrollment_period end date and transition into open_enrollment" do
              expect(benefit_application.open_enrollment_end_on).to eq valid_date
              expect(benefit_application.aasm_state).to eq(:enrollment_open)
            end

            context "and the application cannot transition into open_enrollment_state" do
              let(:invalid_open_enrollment_transition_state)  { :draft }

              before do
                benefit_application.open_enrollment_period = open_enrollment_period
                benefit_application.aasm_state = invalid_open_enrollment_transition_state
                benefit_application.extend_open_enrollment_period(valid_date)
              end

              it "transition into open enrollment should be invalid" do
                expect(benefit_application.may_begin_open_enrollment?).to eq false
              end

              it "should not change the open_enrollment_period or transition into open_enrollment" do
                expect(benefit_application.open_enrollment_end_on).to eq open_enrollment_period_end_on
                expect(benefit_application.aasm_state).to eq(invalid_open_enrollment_transition_state)
              end

            end
          end
        end
      end

      describe "Scopes", :dbclean => :after_each do
        let(:this_year)                       { TimeKeeper.date_of_record.year }
        let(:march_effective_date)            { Date.new(this_year,3,1) }
        let(:march_open_enrollment_begin_on)  { march_effective_date - 1.month }
        let(:march_open_enrollment_end_on)    { march_open_enrollment_begin_on + 9.days }
        let(:april_effective_date)            { Date.new(this_year,4,1) }
        let(:april_open_enrollment_begin_on)  { april_effective_date - 1.month }
        let(:april_open_enrollment_end_on)    { april_open_enrollment_begin_on + 9.days }

        let!(:march_sponsors)                 do
          FactoryBot.create_list(:benefit_sponsors_benefit_application, 3,
                                 effective_period: (march_effective_date..(march_effective_date + 1.year - 1.day)))
        end
        let!(:april_sponsors)                 do
          FactoryBot.create_list(:benefit_sponsors_benefit_application, 2,
                                 effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)))
        end

        before { TimeKeeper.set_date_of_record_unprotected!(Date.today) }


        # it "should find applications by Effective date start" do
        #   expect(BenefitApplications::BenefitApplication.all.size).to eq 5
        #   expect(BenefitApplications::BenefitApplication.effective_date_begin_on(march_effective_date).to_a.sort).to eq march_sponsors.sort
        #   expect(BenefitApplications::BenefitApplication.effective_date_begin_on(april_effective_date).to_a.sort).to eq april_sponsors.sort
        # end

        # it "should find applications by Open Enrollment begin" do
        #   expect(BenefitApplications::BenefitApplication.open_enrollment_begin_on(march_open_enrollment_begin_on).to_a.sort).to eq march_sponsors.sort
        #   expect(BenefitApplications::BenefitApplication.open_enrollment_begin_on(april_open_enrollment_begin_on).to_a.sort).to eq april_sponsors.sort
        # end

        # it "should find applications by Open Enrollment end" do
        #   # binding.pry
        #   expect(BenefitApplications::BenefitApplication.open_enrollment_end_on(march_open_enrollment_end_on).to_a.sort).to eq march_sponsors.sort
        #   expect(BenefitApplications::BenefitApplication.open_enrollment_end_on(april_open_enrollment_end_on).to_a.sort).to eq april_sponsors.sort
        # end

        # it "should find applications in Plan Draft status" do
        #   expect(BenefitApplications::BenefitApplication.draft.to_a.sort).to eq (march_sponsors + april_sponsors).sort
        # end

        # it "should find applications with chained scopes" do
        #   expect(BenefitApplications::BenefitApplication.
        #                                   draft.
        #                                   open_enrollment_begin_on(april_open_enrollment_begin_on)).to eq april_sponsors
        # end

        it "should find applications in Plan Design Exception status"
        it "should find applications in Plan Design Approved status"
        it "should find applications in Enrolling status"
        it "should find applications in Enrollment Eligible status"
        it "should find applications in Enrollment Ineligible status"
        it "should find applications in Coverage Effective status"
        it "should find applications in Terminated status"
        it "should find applications in Expired Effective status"


        # context "with an application in renewing status" do
        #   let(:last_year)                       { this_year - 1 }
        #   let(:last_march_effective_date)       { Date.new(last_year,3,1) }
        #   let!(:initial_application)            { FactoryBot.create(:benefit_sponsors_benefit_application,
        #                                           effective_period: (last_march_effective_date..(last_march_effective_date + 1.year - 1.day)) )}
        #   let!(:renewal_application)            { FactoryBot.create(:benefit_sponsors_benefit_application,
        #                                           effective_period: (march_effective_date..(march_effective_date + 1.year - 1.day)),
        #                                           predecessor_application: initial_application)}

        #   it "should find the renewing application" do
        #     expect(BenefitApplications::BenefitApplication.is_renewing).to eq [renewal_application]
        #     expect(BenefitApplications::BenefitApplication.is_renewing.first.is_renewing?).to eq true
        #     expect(BenefitApplications::BenefitApplication.is_renewing.first.predecessor_application).to eq initial_application
        #     expect(BenefitApplications::BenefitApplication.is_renewing.first.predecessor_application.successor_applications).to eq [renewal_application]
        #     expect(BenefitApplications::BenefitApplication.is_renewing.first.predecessor_application.is_renewing?).to eq false
        #   end
        # end
      end

      describe "Transitioning a BenefitApplication through Plan Design states" do
        let(:employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
        let(:benefit_sponsorship)     { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new(profile: employer_organization.employer_profile) }
        let(:benefit_application)     { described_class.new(valid_params) }


        before do
          benefit_application.benefit_sponsorship = benefit_sponsorship
          benefit_application.save!
        end

        context "Happy path workflow" do

          it "should initialize in state: :draft" do
            expect(benefit_application.aasm_state).to eq :draft
          end

          context "and the application is submitted outside open enrollment period" do
            before { benefit_application.approve_application! }
            it "should transition to state: :approved" do
              expect(benefit_application.aasm_state).to eq :approved
            end

            context "and open enrollment period begins" do
              before do
                TimeKeeper.set_date_of_record_unprotected!(benefit_application.open_enrollment_period.min)
                benefit_application.begin_open_enrollment!
              end
              after { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

              it "should transition to state: :enrollment_open" do
                expect(benefit_application.aasm_state).to eq :enrollment_open
              end

              context "and open enrollment period ends" do
                before { benefit_application.end_open_enrollment! }

                it "should transition to state: :enrollment_closed" do
                  expect(benefit_application.aasm_state).to eq :enrollment_closed
                end

                context "and binder payment is made" do
                  before {benefit_application.credit_binder!}

                  it "should transition to state :binder_paid" do
                    expect(benefit_application.aasm_state).to eq :binder_paid
                  end

                  context "and application is eligible" do
                    before { benefit_application.approve_enrollment_eligiblity! }

                    it "should transition to state: :enrollment_eligible" do
                      expect(benefit_application.aasm_state).to eq :enrollment_eligible
                    end

                    context "and effective period begins" do
                      before { benefit_application.activate_enrollment! }

                      it "should transition to state: :approved" do
                        expect(benefit_application.aasm_state).to eq :active
                      end
                    end
                  end
                end
              end
            end
          end

          context 'revert reverse_enrollment_eligibility' do
            before do
              benefit_application.update_attributes(aasm_state: :binder_paid)
              benefit_application.reverse_enrollment_eligibility!
            end

            it "should transition to state: :enrollment_closed" do
              expect(benefit_application.aasm_state).to eq :enrollment_closed
            end
          end

          context 'revert benefit_application' do
            before do
              benefit_application.update_attributes(aasm_state: :binder_paid)
              benefit_application.revert_application!
            end

            it "should transition to state: :draft" do
              expect(benefit_application.aasm_state).to eq :draft
            end
          end

          context 'activate_enrollment' do
            before do
              benefit_application.update_attributes(aasm_state: :binder_paid)
              benefit_application.activate_enrollment!
            end

            it "should transition to state: :active" do
              expect(benefit_application.aasm_state).to eq :active
            end
          end

          context 'from_state reinstated' do
            before do
              benefit_application.update_attributes!(aasm_state: :reinstated)
              benefit_application.activate_enrollment!
            end

            it 'should transition to state: :active' do
              expect(benefit_application.aasm_state).to eq :active
            end
          end
        end

        context 'reinstate' do
          before do
            benefit_application.reinstate!
            @workflow_state_transition = benefit_application.reload.workflow_state_transitions.first
          end

          it 'should transition from draft to reinstated' do
            expect(benefit_application.reload.aasm_state).to eq(:reinstated)
          end

          it 'should record transition' do
            expect(@workflow_state_transition.from_state).to eq('draft')
            expect(@workflow_state_transition.to_state).to eq('reinstated')
          end
        end

        context "Conversion workflow" do

          it "should initialize in state: :draft" do
            expect(benefit_application.aasm_state).to eq :draft
          end

          context "and its a conversion application" do
            before { benefit_application.import_application! }

            it "should transition to state :imported" do
              expect(benefit_application.aasm_state).to eq :imported
            end

            context "and the application is submitted" do
              before { benefit_application.approve_application! }

              it "should transition to state: :approved" do
                expect(benefit_application.aasm_state).to eq :approved
              end
            end
          end
        end
      end

      describe '.is_off_cycle' do
        let(:current_date1)                  { TimeKeeper.date_of_record.beginning_of_month.prev_month }
        let!(:effective_period)              { (current_date1)..(current_date1.next_year.prev_day) }
        let!(:renewal_effective_period)      { (current_date1.next_year)..(current_date1.prev_day + 2.years) }
        let(:termination_date)               {renewal_effective_period.min + 65.days}
        let(:offcycle_effective_period) do
          date = termination_date.end_of_month.next_day
          date..date.next_year.prev_day
        end
        let!(:initial_application) do
          application = FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: :termination_pending, effective_period: effective_period, benefit_sponsorship: benefit_sponsorship)
          terminated_period = effective_period.min..termination_date
          application.update_attributes!(effective_period: terminated_period)
          application
        end
        let!(:offcycle_application) do
          FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: :draft, effective_period: offcycle_effective_period, benefit_sponsorship: benefit_sponsorship)
        end

        it { expect(initial_application.is_off_cycle?).to be_falsey }
        it { expect(offcycle_application.is_off_cycle?).to be_truthy }
      end

      ## TODO: Refactor for BenefitApplication
      # context "#to_plan_year", dbclean: :after_each do
      #   let(:benefit_application)       { BenefitSponsors::BenefitApplications::BenefitApplication.new(params) }
      #   let(:benefit_sponsorship)       { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new(benefit_market: :aca_shop_cca) }
      #   let(:address)  { Address.new(kind: "primary", address_1: "609 H St NE", city: "Washington", state: "DC", zip: "20002", county: "County") }
      #   let(:phone  )  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
      #   let(:office_location) { OfficeLocation.new(
      #       is_primary: true,
      #       address: address,
      #       phone: phone
      #     )
      #   }

      #   let(:plan_design_organization)  { BenefitSponsors::Organizations::PlanDesignOrganization.new(legal_name: "xyz llc") }
      #   let(:plan_design_proposal)      { BenefitSponsors::Organizations::PlanDesignProposal.new(title: "New Proposal") }
      #   let(:profile) {BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new}

      #   before(:each) do
      #     plan_design_organization.plan_design_proposals << [plan_design_proposal]
      #     plan_design_proposal.profile = profile
      #     profile.organization.benefit_sponsorships = [benefit_sponsorship]
      #     benefit_sponsorship.benefit_applications  = [benefit_application]
      #     benefit_application.benefit_packages.build
      #     plan_design_organization.save
      #   end

      #   it "should instantiate a plan year object and must have correct values assigned" do
      #     plan_year = benefit_application.to_plan_year
      #     expect(plan_year.class).to eq PlanYear
      #     expect(plan_year.benefit_groups.present?).to eq true
      #     expect(plan_year.start_on).to eq benefit_application.effective_period.begin
      #     expect(plan_year.end_on).to eq benefit_application.effective_period.end
      #     expect(plan_year.open_enrollment_start_on).to eq benefit_application.open_enrollment_period.begin
      #     expect(plan_year.open_enrollment_end_on).to eq benefit_application.open_enrollment_period.end
      #   end
      # end

      describe ".renew" do
        before(:each) do
          ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
          ::BenefitMarkets::Products::ProductFactorCache.initialize_factor_cache!
        end

        context "when renewal benefit sponsor catalog available" do
          # Create site
          # Create benefit market
          # Create employer organization with profile
          # Create benefit sponsorships
          # Create benefit applications
          # Create benefit sponsor catalogs

          let(:renewal_effective_date) { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
          let(:current_effective_date) { renewal_effective_date.prev_year }
          let(:effective_period) { current_effective_date..current_effective_date.next_year.prev_day }
          let(:package_kind)            { :single_issuer }
          let(:application_period_next_year)        { (Date.new(renewal_effective_date.year,1,1))..(Date.new(renewal_effective_date.year,12,31)) }
          let!(:employer_profile) {benefit_sponsorship.profile}
          let!(:initial_application) { create(:benefit_sponsors_benefit_application, benefit_sponsor_catalog: benefit_sponsor_catalog, effective_period: effective_period,benefit_sponsorship: benefit_sponsorship, aasm_state: :active) }
          let(:product_package)           { initial_application.benefit_sponsor_catalog.product_packages.detect { |package| package.package_kind == package_kind } }
          let(:benefit_package)   do
            bp = create(:benefit_sponsors_benefit_packages_benefit_package, health_sponsored_benefit: true, product_package: product_package, benefit_application: initial_application)
            reference_product = bp.sponsored_benefits.first.reference_product
            reference_product.renewal_product = product
            reference_product.save!
            bp
          end
          let(:benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment, start_on: benefit_package.start_on, benefit_group_id: nil, benefit_package_id: benefit_package.id, is_active: true)}
          let!(:census_employee) do
            FactoryBot.create(:census_employee, employer_profile_id: nil, benefit_sponsors_employer_profile_id: employer_profile.id, benefit_sponsorship: benefit_sponsorship, :benefit_group_assignments => [benefit_group_assignment])
          end
          let(:renewal_application) do
            application = initial_application.renew
            application.save
            application
          end
          let(:census_employee_scope) do
            CensusEmployee.where(:_id.in => [census_employee_1.id, census_employee_2.id])
          end
          let(:renewal_bga) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: renewal_application.benefit_packages.first, census_employee: census_employee, is_active: false)}
          let(:renewal_product_package)    { benefit_market_catalog_next_year.product_packages.detect { |package| package.package_kind == package_kind } }
          let(:product) { renewal_product_package.products[0] }

          it "should generate renewal application" do
            expect(renewal_application.predecessor).to eq initial_application
            expect(renewal_application.effective_period.begin).to eq renewal_effective_date
          end

          context "send_employee_renewal_invites" do
            let!(:census_employee_1) do
              FactoryBot.create(:census_employee, benefit_sponsors_employer_profile_id: employer_profile.id, benefit_sponsorship: benefit_sponsorship, :benefit_group_assignments => [benefit_group_assignment])
            end
            let!(:census_employee_2) do
              FactoryBot.create(:census_employee, benefit_sponsors_employer_profile_id: employer_profile.id, benefit_sponsorship: benefit_sponsorship, :benefit_group_assignments => [benefit_group_assignment])
            end
            let(:census_employee_scope) do
              CensusEmployee.where(:_id.in => [census_employee_1.id, census_employee_2.id])
            end

            let(:fake_email_address) {"fakeemail1@fakeemail.com" }

            context "same employer, same email" do
              before :each do
                ::Invitation.destroy_all
                renewal_application.save!
                renewal_bga
                CensusEmployee.all.each do |ce|
                  allow(ce).to receive(:email_address).and_return(fake_email_address)
                  allow(ce.renewal_benefit_group_assignment).to receive(:benefit_application).and_return(renewal_application)
                  allow(ce).to receive(:benefit_sponsors_employer_profile_id).and_return(employer_profile.id)
                end
                allow(renewal_application.benefit_sponsorship).to receive(:census_employees).and_return(census_employee_scope)
                allow(TimeKeeper).to receive(:date_of_record).and_return(Time.now + 1.month)
              end

              it "should not send duplicate invitations, even with time travel activated" do
                renewal_application.send_employee_renewal_invites
                expect(::Invitation.count).to eq(2)
                renewal_application.send_employee_renewal_invites
                expect(::Invitation.count).to eq(2)
              end
            end
          end

          context "when renewal application saved" do

            before do
              renewal_application.save
              renewal_bga
            end

            it "should create renewal benefit group assignment" do
              #expect(census_employee.active_benefit_group_assignment.benefit_application).to eq initial_application
              expect(census_employee.renewal_benefit_group_assignment.benefit_application).to eq renewal_application
            end

            it "renewal benefit group assignment is_active set to false" do
              expect(census_employee.renewal_benefit_group_assignment.activated_at).to eq nil
            end
          end

          context "when renewal application moved to enrollment_open state" do
            before do
              renewal_bga
              renewal_application.aasm_state = :enrollment_open
              renewal_application.recorded_rating_area = rating_area
              renewal_application.recorded_service_areas = [service_area]
              renewal_application.recorded_sic_code = sic_code
              renewal_application.save!
            end

            it "should not update benefit group assignments" do
              expect(renewal_application.aasm_state).to eq :enrollment_open
              expect(census_employee.renewal_benefit_group_assignment.benefit_application).to eq renewal_application
              expect(census_employee.active_benefit_group_assignment.benefit_application).to eq initial_application
            end
          end

          context "when renewal application moved to active state" do
            before do
              renewal_bga
              renewal_application.aasm_state = :enrollment_eligible
              renewal_application.recorded_rating_area = rating_area
              renewal_application.recorded_service_areas = [service_area]
              renewal_application.recorded_sic_code = sic_code
              initial_application.update_attributes(predecessor_id: renewal_application.id)
              renewal_application.renew_benefit_package_assignments
              renewal_application.save!
              renewal_application.activate_enrollment!
            end

            it "should activate renewal benefit group assignment & set is_active to true" do
              expect(renewal_application.aasm_state).to eq :active
              renewal_bga = census_employee.benefit_group_assignments.effective_on(renewal_application.effective_period.min).first
              expect(renewal_bga.benefit_application).to eq renewal_application
              expect(census_employee.active_benefit_group_assignment.is_active).to eq true
            end

            xit "should deactivate active benefit group assignment" do
              expect(census_employee.benefit_group_assignments.where(benefit_package_id: benefit_package.id).first.is_active).to eq false
            end
          end

          context "based on exchange's rules" do

            context 'when current benefit application has flex rules and renewals are not allowed to get flex rules' do
              let(:renewal_year) { initial_application.start_on.next_year.year }
              let(:flex_setting) { initial_application.start_on.month == 1 ? EnrollRegistry["renewal_sponsor_jan_default_#{renewal_year}"] : EnrollRegistry["renewal_sponsor_default_#{renewal_year}"] }
              let(:flex_contribution_setting) { flex_setting.setting(:contribution_model_key) }
              let(:flex_period) { flex_setting.setting(:effective_period).item }
              let(:flex_setting_enabled) do
                initial_application.start_on.month == 1 ? EnrollRegistry.feature_enabled?("renewal_sponsor_jan_default_#{renewal_year}") : EnrollRegistry.feature_enabled?("renewal_sponsor_default_#{renewal_year}")
              end
              let(:contribution_model1) {renewal_application.benefit_packages.first.sponsored_benefits[0].contribution_model}

              before :each do
                allow(flex_contribution_setting).to receive(:item).and_return(:fifty_percent_sponsor_fixed_percent_contribution_model)
              end

              it "should set minimum contributions percentage" do
                expect(contribution_model1.key).to eq :fifty_percent_sponsor_fixed_percent_contribution_model if flex_setting_enabled && flex_period.cover?(renewal_application.start_on)
              end
            end

            context 'when current benefit application doesnt have flex rules and renewals are allowed to get flex rules' do
              let(:renewal_effective_period) { effective_period.min.next_year..effective_period.max.next_year }
              let(:renewal_start_on_year) { renewal_effective_period.min.year }
              let(:initial_flex_setting) do
                effective_period.min.yday == 1 ? EnrollRegistry["initial_sponsor_jan_default_#{effective_period.min.year}"] : EnrollRegistry["initial_sponsor_default_#{effective_period.min.year}"]
              end
              let(:initial_flex_contribution_setting) { initial_flex_setting.setting(:contribution_model_key) }
              let(:initial_flex_period) { flex_setting.setting(:effective_period).item }

              let(:renewal_flex_setting) do
                renewal_effective_period.min.yday == 1 ? EnrollRegistry["renewal_sponsor_jan_default_#{renewal_start_on_year}"] : EnrollRegistry["renewal_sponsor_default_#{renewal_start_on_year}"]
              end
              let(:renewal_flex_contribution_setting) { renewal_flex_setting.setting(:contribution_model_key) }
              let(:renewal_flex_period) { renewal_flex_setting.setting(:effective_period).item }
              let(:renewal_flex_setting_enabled) { EnrollRegistry.feature_enabled?("renewal_sponsor_default_#{renewal_start_on_year}") }
              let(:contribution_model2) { renewal_application.benefit_packages.first.sponsored_benefits[0].contribution_model }

              before :each do
                allow(initial_flex_contribution_setting).to receive(:item).and_return(:fifty_percent_sponsor_fixed_percent_contribution_model)
                allow(renewal_flex_contribution_setting).to receive(:item).and_return(:zero_percent_sponsor_fixed_percent_contribution_model)
              end

              it "should set minimum contributions percentage" do
                expect(contribution_model2.key).to eq :zero_percent_sponsor_fixed_percent_contribution_model if renewal_flex_setting_enabled && renewal_flex_period.cover?(renewal_effective_period.min)
              end
            end
          end
        end
      end

      describe "enrollments_till_given_effective_on" do
        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup initial benefit application"
        context "No hbx_enrollments for the benefit application" do
          it "No hbx_enrollment under the benefit application" do
            expect(benefit_sponsorship.benefit_applications.first.hbx_enrollments.count).to eq 0
          end
        end

        context "HbxEnrollment available for benefit application return the enrollment with the given date" do
          before do
            enrollment = HbxEnrollment.new(effective_on: Date.today.next_month.beginning_of_month)
            enrollment1 = HbxEnrollment.new(effective_on: Date.today.next_month.beginning_of_month + 2.months)
            benefit_sponsorship.benefit_applications.first.hbx_enrollments << enrollment
            benefit_sponsorship.benefit_applications.first.hbx_enrollments << enrollment1
            benefit_sponsorship.benefit_applications.first.save
          end

          it "Benefit application should have enrollment under the application" do
            expect(benefit_sponsorship.benefit_applications.first.hbx_enrollments.count).not_to eq 0
          end

          it "Benefit application should have enrollment under the application" do
            expect(benefit_sponsorship.benefit_applications.first.hbx_enrollments.count).to eq 2
          end

          it "Should return the enrollments only with the effective date as next month start date" do
            expect(benefit_sponsorship.benefit_applications.first.enrollments_till_given_effective_on(Date.today.next_month.beginning_of_month).count).not_to eq 0
          end

          it "should not return enrollment outside given date" do
            expect(benefit_sponsorship.benefit_applications.first.enrollments_till_given_effective_on(Date.today.next_month.beginning_of_month).count).to eq 1
          end

          it "should return enrollments within the given date" do
            expect(benefit_sponsorship.benefit_applications.first.enrollments_till_given_effective_on(Date.today.next_month.beginning_of_month + 2.months).count).to eq 2
          end
        end
      end

      describe "Date period behaviors" do
        let(:subject)             { BenefitApplications::BenefitApplicationSchedular.new }
        let(:begin_day) do
          Settings.aca.shop_market.open_enrollment.monthly_end_on -
            Settings.aca.shop_market.open_enrollment.minimum_length.adv_days
        end
        let(:grace_begin_day) do
          Settings.aca.shop_market.open_enrollment.monthly_end_on -
            Settings.aca.shop_market.open_enrollment.minimum_length.days
        end

        def standard_begin_day
          begin_day > 0 ? begin_day : 1
        end

        it "should return the day of month deadline for an open enrollment standard period to begin" do
          expect(subject.open_enrollment_minimum_begin_day_of_month).to eq standard_begin_day
        end

        it "should return the day of month deadline for an open enrollment grace period to begin" do
          expect(subject.open_enrollment_minimum_begin_day_of_month(true)).to eq grace_begin_day
        end

        context "and a calendar date is passed to effective period by date method" do
          let(:seed_date)                         { TimeKeeper.date_of_record + 2.months + 3.days }
          let(:next_month_begin_on)               { seed_date.beginning_of_month + 1.month }
          let(:next_month_effective_period)       { next_month_begin_on..(next_month_begin_on + 1.year - 1.day) }
          let(:following_month_begin_on)          { seed_date.beginning_of_month + 2.months }
          let(:following_month_effective_period)  { following_month_begin_on..(following_month_begin_on + 1.year - 1.day) }

          let(:standard_period_last_day)          { subject.open_enrollment_minimum_begin_day_of_month }
          let(:standard_period_deadline_date)     { Date.new(seed_date.year, seed_date.month, standard_period_last_day) }
          let(:standard_period_pre_deadline_date) { standard_period_deadline_date - 1.day }

          let(:grace_period_last_day)             { subject.open_enrollment_minimum_begin_day_of_month(true) }
          let(:grace_period_deadline_date)        { Date.new(seed_date.year, seed_date.month, grace_period_last_day) }
          let(:grace_period_post_deadline_date)   { grace_period_deadline_date + 1.day }


          context "that is before standard period deadline" do
            it "should provide an effective (standard) period beginning the first of next month" do
              expect(subject.effective_period_by_date(standard_period_pre_deadline_date)).to eq next_month_effective_period
            end

            it "should provide an effective (grace) period beginning the first of next month" do
              expect(subject.effective_period_by_date(standard_period_pre_deadline_date, true)).to eq next_month_effective_period
            end
          end

          context "that is the same day as the standard period deadline" do
            it "should provide an effective (standard) period beginning the first of next month" do
              expect(subject.effective_period_by_date(standard_period_deadline_date)).to eq next_month_effective_period
            end

            it "should provide an effective (grace) period beginning the first of next month" do
              expect(subject.effective_period_by_date(standard_period_deadline_date, true)).to eq next_month_effective_period
            end
          end

          # TODO: Open enrollment minimum length setting for days & adv_days same.
          #       Following spec need to be improved to handle this scenario.
          # context "that is after the standard period, but before the grace period deadline" do
          #   it "should provide an effective (standard) period beginning the first of month following next month" do
          #     expect(subject.effective_period_by_date(grace_period_deadline_date)).to eq following_month_effective_period
          #   end

          #   it "should provide an effective (grace) period beginning the of first next month" do
          #     expect(subject.effective_period_by_date(grace_period_deadline_date, true)).to eq next_month_effective_period
          #   end
          # end

          context "that is after both the standard and grace period deadlines" do
            it "should provide an effective (standard) period beginning the first of month following next month" do
              expect(subject.effective_period_by_date(grace_period_post_deadline_date)).to eq following_month_effective_period
            end

            it "should provide an effective (grace) period beginning the first of month following next month" do
              expect(subject.effective_period_by_date(grace_period_post_deadline_date, true)).to eq following_month_effective_period
            end
          end
        end

        context "and an effective date is passed to open enrollment period by effective date method" do
          let(:effective_date)                  { (TimeKeeper.date_of_record + 3.months).beginning_of_month }
          let(:prior_month)                     { effective_date - 1.month }
          let(:valid_open_enrollment_begin_on)  { effective_date - Settings.aca.shop_market.open_enrollment.maximum_length.months.months }
          let(:valid_open_enrollment_end_on)    { Date.new(prior_month.year, prior_month.month, Settings.aca.shop_market.open_enrollment.monthly_end_on) }
          let(:valid_open_enrollment_period)    { valid_open_enrollment_begin_on..valid_open_enrollment_end_on }

          it "should provide a valid open enrollment period for that effective date" do
            expect(subject.open_enrollment_period_by_effective_date(false, effective_date)).to eq valid_open_enrollment_period
          end
        end

        context "and an effective date is passed to enrollment timetable by effective date method" do
          let(:effective_date)                  { TimeKeeper.date_of_record.next_month.end_of_month + 1.day }
          let(:prior_month)                     { effective_date - 1.month }
          let(:begin_day) do
            Settings.aca.shop_market.open_enrollment.monthly_end_on -
              Settings.aca.shop_market.open_enrollment.minimum_length.adv_days
          end

          let(:open_enrollment_end_day)         { Settings.aca.shop_market.open_enrollment.monthly_end_on }
          let(:open_enrollment_end_on)          { Date.new(prior_month.year, prior_month.month, open_enrollment_end_day) }

          let(:late_open_enrollment_begin_on)   { Date.new(prior_month.year, prior_month.month, late_open_enrollment_begin_day) }
          let(:late_open_enrollment_period)     { late_open_enrollment_begin_on..open_enrollment_end_on }

          let(:binder_payment_due_on) do
            Date.new(prior_month.year, prior_month.month, Settings.aca.shop_market.binder_payment_due_on)
          end

          let(:valid_timetable) do
            {
              effective_date: effective_date,
              effective_period: effective_date..(effective_date.next_year - 1.day),
              open_enrollment_period: TimeKeeper.date_of_record..open_enrollment_end_on,
              open_enrollment_period_minimum: late_open_enrollment_period,
              binder_payment_due_on: binder_payment_due_on
            }
          end
          def late_open_enrollment_begin_day
            begin_day > 0 ? begin_day : 1
          end

          it "should provide a valid an enrollment timetabe hash for that effective date" do
            expect(subject.enrollment_timetable_by_effective_date(false, effective_date)).to eq valid_timetable
          end

          it "timetable date values should be valid" do
            timetable = subject.enrollment_timetable_by_effective_date(false, effective_date)

            expect(BenefitApplications::BenefitApplication.new(
                     effective_period: timetable[:effective_period],
                     open_enrollment_period: timetable[:open_enrollment_period],
                     recorded_service_areas: [service_area],
                     recorded_rating_area: rating_area,
                     recorded_sic_code: sic_code
                   )).to be_valid
          end
        end
      end

      describe ".open_enrollment_length" do
        let!(:initial_application) do
          FactoryBot.create(
            :benefit_sponsors_benefit_application,
            benefit_sponsor_catalog: benefit_sponsor_catalog,
            effective_period: effective_period,
            benefit_sponsorship: benefit_sponsorship,
            aasm_state: :active
          )
        end
        let(:min_open_enrollment_length) { 5 }
        let(:start_date) {Date.new(2019,11,16)}
        let(:end_date) {Date.new(2019,11,20)}

        it 'open_enrollment_length should be greater than min_open_enrollment_length' do
          initial_application.update_attributes(open_enrollment_period: (start_date..(end_date + 1.day)))
          expect(initial_application.open_enrollment_length).to be > min_open_enrollment_length
        end

        it 'open_enrollment_length should be equal to min_open_enrollment_length ' do
          initial_application.update_attributes(open_enrollment_period: (start_date..end_date))
          expect(initial_application.open_enrollment_length).to eq min_open_enrollment_length
        end

        it 'open_enrollment_length should be less than min_open_enrollment_length ' do
          initial_application.update_attributes(open_enrollment_period: (start_date..(end_date - 1.day)))
          expect(initial_application.open_enrollment_length).to be < min_open_enrollment_length
        end
      end

      describe "Navigating BenefitSponsorship Predecessor/Successor linked list", :dbclean => :after_each do
        let(:node_a)    do
          described_class.new(benefit_sponsorship: benefit_sponsorship,
                              effective_period: effective_period,
                              open_enrollment_period: open_enrollment_period,
                              recorded_sic_code: sic_code,
                              recorded_rating_area: rating_area,
                              recorded_service_areas: [service_area])
        end
        let(:node_a1)   do
          described_class.new(benefit_sponsorship: benefit_sponsorship,
                              effective_period: effective_period,
                              open_enrollment_period: open_enrollment_period,
                              recorded_sic_code: sic_code,
                              recorded_rating_area: rating_area,
                              recorded_service_areas: [service_area],
                              predecessor: node_a)
        end
        let(:node_a1a)  do
          described_class.new(benefit_sponsorship: benefit_sponsorship,
                              effective_period: effective_period,
                              open_enrollment_period: open_enrollment_period,
                              recorded_sic_code: sic_code,
                              recorded_rating_area: rating_area,
                              recorded_service_areas: [service_area],
                              predecessor: node_a1)
        end
        let(:node_b1)   do
          described_class.new(benefit_sponsorship: benefit_sponsorship,
                              effective_period: effective_period,
                              open_enrollment_period: open_enrollment_period,
                              recorded_sic_code: sic_code,
                              recorded_rating_area: rating_area,
                              recorded_service_areas: [service_area],
                              predecessor: node_a)
        end

        it "should manage predecessors", :aggregate_failures do
          expect(node_a1a.predecessor).to eq node_a1
          expect(node_a1.predecessor).to eq node_a
          expect(node_b1.predecessor).to eq node_a
          expect(node_a.predecessor).to eq nil
        end

        context "and the BenefitApplications are persisted" do
          before do
            node_a.save!
            node_a1.save!
            node_a1a.save!
            node_b1.save!
          end

          it "should maintain linked lists for successors", :aggregate_failures do
            expect(node_a.successors).to contain_exactly(node_a1, node_b1)
            expect(node_a1.successors).to eq [node_a1a]
          end
        end
      end

      describe "after_create actions" do
        let(:employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
        let(:benefit_sponsorship)     { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new(profile: employer_organization.employer_profile) }
        let(:benefit_application)     { described_class.new(valid_params) }

        before do
          benefit_application.benefit_sponsorship = benefit_sponsorship
          benefit_application.save!
        end

        context "for expiration_date" do
          it "should default to min date of effective_period" do
            expect(benefit_application.expiration_date).to eq(benefit_application.effective_period.min)
          end

          it "should not default to max date of effective_period" do
            expect(benefit_application.expiration_date).not_to eq(benefit_application.effective_period.max)
          end
        end
      end

      describe '.enrolled_families',dbclean: :after_each do
        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup initial benefit application"
        include_context "setup employees with benefits"

        let!(:people) { create_list(:person, 5, :with_employee_role, :with_family) }

        before do
          people.each_with_index do |person, i|
            ce = census_employees[i]
            family = person.primary_family
            ce.update_attributes!(employee_role_id: person.employee_roles.first.id)
            FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
          end
        end

        it 'should return enrolled families count' do
          expect(initial_application.enrolled_families.count).to eq benefit_sponsorship.census_employees.count
        end
      end

      describe '.active_and_cobra_enrolled_families',dbclean: :after_each do
        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup initial benefit application"
        include_context "setup employees with benefits"

        let!(:people) { create_list(:person, 5, :with_employee_role, :with_family) }

        before do
          people.each_with_index do |person, i|
            ce = census_employees[i]
            family = person.primary_family
            ce.update_attributes!(employee_role_id: person.employee_roles.first.id)
            FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
          end
        end

        it 'should return enrolled families count' do
          expect(initial_application.active_and_cobra_enrolled_families.count).to eq benefit_sponsorship.census_employees.count
        end

        context 'when family has only enrolled in dental coverage' do

          let(:dental_person) { FactoryBot.create(:person, :with_employee_role, :with_family) }
          let(:dental_family) { dental_person.primary_family }
          let!(:dental_sponsored_benefit) { true }
          let(:dental_census_employee) do
            ce = FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package)
            ce.update_attributes!(employee_role_id: dental_person.employee_roles.first.id)
            ce
          end

          let!(:dental_enrollment) do
            FactoryBot.create(
              :hbx_enrollment,
              family: dental_family,
              household: dental_family.active_household,
              benefit_group_assignment: dental_census_employee.benefit_group_assignments.first,
              sponsored_benefit_package_id: dental_census_employee.benefit_group_assignments.first.benefit_package.id,
              coverage_kind: 'dental'
            )
          end

          it 'should return enrolled families count' do
            expect(initial_application.active_and_cobra_enrolled_families.count).to eq benefit_sponsorship.census_employees.count
          end
        end
      end

      describe '.predecessor_benefit_package', dbclean: :after_each do
        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup renewal application"

        it 'should return predecessor benefit package' do
          expect(renewal_application.predecessor_benefit_package(benefit_package)).to eq current_benefit_package
        end
      end

      describe '.active_census_employees_under_py', dbclean: :after_each do
        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup renewal application"
        include_context "setup employees with benefits"

        before :each do
          renewal_application.benefit_packages.first.update_attributes!(_id: CensusEmployee.all.first.benefit_group_assignments.first.benefit_package_id)
        end

        it 'should not return the terminated EEs' do
          expect(renewal_application.active_census_employees_under_py.count).to eq 5
          term_date = renewal_application.effective_period.min - 10.days
          ce = renewal_application.active_census_employees_under_py.first
          ce.benefit_group_assignments.first.update_attributes!(start_on: renewal_application.effective_period.min + 1.day)
          ce.aasm_state = 'employment_terminated'
          ce.employment_terminated_on = term_date
          ce.benefit_group_assignments.last.update(benefit_package_id: renewal_application.benefit_packages.first.id)
          ce.save(validate: false)
          expect(renewal_application.active_census_employees_under_py.count).to eq 4
        end

        it 'should not return term pending with prior effective date as term date' do
          expect(renewal_application.active_census_employees_under_py.count).to eq 5
          term_date = renewal_application.effective_period.min - 10.days
          ce = renewal_application.active_census_employees_under_py.first
          ce.benefit_group_assignments.first.update_attributes!(start_on: renewal_application.effective_period.min + 1.day)
          ce.aasm_state = 'employee_termination_pending'
          ce.employment_terminated_on = term_date
          ce.benefit_group_assignments.last.update(benefit_package_id: renewal_application.benefit_packages.first.id)
          ce.save(validate: false)
          expect(renewal_application.active_census_employees_under_py.count).to eq 4
        end

        it 'should return term pending with effective date as term date' do
          expect(renewal_application.active_census_employees_under_py.count).to eq 5
          term_date = renewal_application.effective_period.min
          ce = renewal_application.active_census_employees_under_py.first
          ce.aasm_state = 'employee_termination_pending'
          ce.employment_terminated_on = term_date
          expect(renewal_application.active_census_employees_under_py.count).to eq 5
        end

        it 'should return term pending with future effective date as term date' do
          expect(renewal_application.active_census_employees_under_py.count).to eq 5
          term_date = renewal_application.effective_period.min + 1.day
          ce = renewal_application.active_census_employees_under_py.first
          ce.aasm_state = 'employee_termination_pending'
          ce.employment_terminated_on = term_date
          expect(renewal_application.active_census_employees_under_py.count).to eq 5
        end
      end

      describe '.all_waived_member_count', dbclean: :after_each do
        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup renewal application"
        include_context "setup employees with benefits"

        before :each do
          employees = []
          benefit_sponsorship.census_employees.each do |ce|
            family = FactoryBot.create(:family, :with_primary_family_member)
            allow(ce).to receive(:family).and_return(family)
            allow(ce).to receive(:is_waived_under?).and_return true
            employees << ce
          end
          allow(renewal_application).to receive(:active_census_employees_under_py).and_return(employees)
        end

        it 'should not return the waived EEs count' do
          expect(renewal_application.all_waived_member_count).to eq 5
        end
      end

      describe '.total_enrolled_and_waived_count',dbclean: :after_each do
        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup initial benefit application"
        include_context "setup employees with benefits"

        let!(:people) { create_list(:person, 5, :with_employee_role, :with_family) }
        let!(:owner_employee) {census_employees.first}

        before do
          people.each_with_index do |person, i|
            ce = census_employees[i]
            family = person.primary_family
            ce.update_attributes!(employee_role_id: person.employee_roles.first.id)
            FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
          end
        end

        it 'should return enrolled families count' do
          owner_employee.update_attributes!(:is_business_owner => true)
          expect(initial_application.total_enrolled_and_waived_count).to eq 4
        end
      end

      describe '.successor_benefit_package', dbclean: :after_each do
        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup renewal application"

        it 'should return successor benefit package' do
          expect(predecessor_application.successor_benefit_package(current_benefit_package)).to eq benefit_package
        end
      end

      describe 'quiet period end date for intial and renewal application', dbclean: :after_each do

        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup renewal application"

        context ".renewal_quiet_period_end", dbclean: :after_each do
          it 'should return renewal quiet period dates' do
            renewal_quiet_period = renewal_application.start_on + Settings.aca.shop_market.renewal_application.quiet_period.month_offset.months + (Settings.aca.shop_market.renewal_application.quiet_period.mday - 1).days
            expect(renewal_application.renewal_quiet_period_end(renewal_application.start_on).mday).to eq 15
            expect(renewal_application.renewal_quiet_period_end(renewal_application.start_on)).to eq renewal_quiet_period
          end
        end

        context ".initial_quiet_period_end", dbclean: :after_each do
          it 'should return initial quiet period dates' do
            inital_quiet_period = predecessor_application.start_on + Settings.aca.shop_market.initial_application.quiet_period.month_offset.months + (Settings.aca.shop_market.initial_application.quiet_period.mday - 1).days
            expect(predecessor_application.initial_quiet_period_end(predecessor_application.start_on).mday).to eq 28
            expect(predecessor_application.initial_quiet_period_end(predecessor_application.start_on)).to eq inital_quiet_period
          end
        end
      end

      describe '.open_enrollment_date_bounds', dbclean: :after_each do
        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup renewal application"

        context "when DATE is After default OE" do

          before do
            prior_month = renewal_application.start_on - 1.month
            TimeKeeper.set_date_of_record_unprotected!(Date.new(prior_month.year, prior_month.month, 14))
          end
          after { TimeKeeper.set_date_of_record_unprotected!(Time.zone.today) }

          context ".renewal open_enrollment_date_bound", dbclean: :after_each do

            it 'should return renewal open_enrollment dates' do
              renewal_start_on = renewal_application.start_on
              renewal_open_enrollment_date_bound = renewal_application.open_enrollment_date_bounds

              expect(renewal_open_enrollment_date_bound[:min]).to eq TimeKeeper.date_of_record
              expect(renewal_open_enrollment_date_bound[:max]).to eq renewal_start_on.end_of_month
            end
          end

          context ".initial open_enrollment_date_bound", dbclean: :after_each do

            before do
              prior_month = predecessor_application.start_on - 1.month
              TimeKeeper.set_date_of_record_unprotected!(Date.new(prior_month.year, prior_month.month, 14))
            end
            after { TimeKeeper.set_date_of_record_unprotected!(Time.zone.today) }

            it 'should return initial open_enrollment dates' do
              inital_start_on = predecessor_application.start_on
              inital_open_enrollment_date_bound = predecessor_application.open_enrollment_date_bounds

              expect(inital_open_enrollment_date_bound[:min]).to eq TimeKeeper.date_of_record
              expect(inital_open_enrollment_date_bound[:max]).to eq inital_start_on.end_of_month
            end
          end
        end

        context "when DATE is Before default OE date" do

          before do
            prior_month = renewal_application.start_on - 1.month
            TimeKeeper.set_date_of_record_unprotected!(Date.new(prior_month.year, prior_month.month, 9))
          end
          after { TimeKeeper.set_date_of_record_unprotected!(Time.zone.today) }

          context ".renewal open_enrollment_date_bound", dbclean: :after_each do

            it 'should return renewal open_enrollment dates' do
              renewal_start_on = renewal_application.start_on
              prior_month = renewal_application.start_on - 1.month
              renewal_open_enrollment_date_bound = renewal_application.open_enrollment_date_bounds

              expect(renewal_open_enrollment_date_bound[:min]).to eq Date.new(prior_month.year, prior_month.month, 13)
              expect(renewal_open_enrollment_date_bound[:max]).to eq renewal_start_on.end_of_month
            end
          end

          context ".initial open_enrollment_date_bound", dbclean: :after_each do

            before do
              prior_month = predecessor_application.start_on - 1.month
              TimeKeeper.set_date_of_record_unprotected!(Date.new(prior_month.year, prior_month.month, 9))
            end
            after { TimeKeeper.set_date_of_record_unprotected!(Time.zone.today) }

            it 'should return initial open_enrollment dates' do
              inital_start_on = predecessor_application.start_on
              prior_month = predecessor_application.start_on - 1.month
              inital_open_enrollment_date_bound = predecessor_application.open_enrollment_date_bounds

              expect(inital_open_enrollment_date_bound[:min]).to eq Date.new(prior_month.year, prior_month.month, 10)
              expect(inital_open_enrollment_date_bound[:max]).to eq inital_start_on.end_of_month
            end
          end
        end
      end

      describe '.enrollment_quiet_period', dbclean: :after_each do
        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup initial benefit application"

        let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }

        context "when intital application open enrollment end date inside plan year start date", dbclean: :after_each do

          it 'return next day of open_enrollment_end date as quiet_period start date' do
            quiet_period = initial_application.enrollment_quiet_period
            expect(quiet_period.min.to_date).to eq initial_application.open_enrollment_period.max + 1.day
          end

          it 'return default quiet_period end date' do
            quiet_period = initial_application.enrollment_quiet_period
            initial_quiet_period_end = initial_application.start_on + Settings.aca.shop_market.initial_application.quiet_period.month_offset.months + (Settings.aca.shop_market.initial_application.quiet_period.mday - 1).days
            expect(quiet_period.max).to eq TimeKeeper.end_of_exchange_day_from_utc(initial_quiet_period_end)
          end
        end

        context "when intital application open enrollment end date outside plan year start date", dbclean: :after_each do

          before do
            initial_application.open_enrollment_period = (current_effective_date - 15.days..current_effective_date + 4.days)
            initial_application.save
          end

          it 'return next day of open_enrollment_end date as quiet_period start date' do
            quiet_period = initial_application.enrollment_quiet_period
            expect(quiet_period.min.to_date).to eq initial_application.open_enrollment_period.max + 1.day
          end

          it 'return next day of quiet_period start date as quiet_period end date' do
            quiet_period = initial_application.enrollment_quiet_period
            expect(quiet_period.max).to eq quiet_period.min + 1.day
          end
        end
      end

      describe '.is_renewing?' do
        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup renewal application"

        let!(:ineligible_application) do
          FactoryBot.create(:benefit_sponsors_benefit_application,
                            :with_benefit_package,
                            :benefit_sponsorship => benefit_sponsorship,
                            :aasm_state => 'enrollment_ineligible',
                            :effective_period => (predecessor_application.effective_period.min - 1.year)..(predecessor_application.effective_period.min.prev_day))
        end

        before do
          benefit_sponsorship.benefit_applications.draft.first.predecessor_id = predecessor_application.id
        end

        context "finding if plan year is a renewal or not" do
          it 'renewing application should return true' do
            expect(benefit_sponsorship.benefit_applications.draft.first.is_renewing?).to eq true
          end

          it 'active application should return false' do
            expect(benefit_sponsorship.benefit_applications.active.first.is_renewing?).to eq false
          end

          it 'old ineligible application should return false' do
            expect(benefit_sponsorship.benefit_applications.enrollment_ineligible.first.is_renewing?).to eq false
          end

          it 'renewal application transitions to enrollment ineligible state' do
            renewal_application.update_attributes(:aasm_state => "enrollment_ineligible")
            expect(renewal_application.is_renewing?).to eq true
          end
        end
      end

      describe '.employee_participation_ratio_minimum' do

        let(:application) { subject.class.new(effective_period: effective_period) }
        let(:market) { double(kind: :aca_shop) }
        let(:start_on) { TimeKeeper.date_of_record }
        let(:benefit_sponsor_catalog) { double(product_packages: [product_package])}
        let(:product_package) { double(benefit_kind: :aca_shop, contribution_model: double(key: :fifty_percent_sponsor_fixed_percent_contribution_model))}

        before do
          allow(application).to receive(:benefit_market).and_return(market)
          allow(application).to receive(:benefit_sponsor_catalog).and_return(benefit_sponsor_catalog)
        end

        context 'when resource registry feature not found' do

          let(:start_on) { TimeKeeper.date_of_record + 2.years }

          context "start on is on january 1st" do
            let(:effective_period) { start_on.beginning_of_year..start_on.end_of_year }

            it 'should return system default minimum ratio' do
              expect(application.employee_participation_ratio_minimum).to eq application.system_min_participation_default_for(effective_period.min)
            end
          end

          context "start on is not on january 1st" do
            let(:effective_period) { Date.new(start_on.year, 2, 1)..Date.new(start_on.year + 1, 1, 31) }

            it 'should return system default minimum ratio' do
              expect(application.employee_participation_ratio_minimum).to eq application.system_min_participation_default_for(effective_period.min)
            end
          end
        end

        context 'when resource registry feature not enabled' do
          let(:market) { double(kind: :fehb) }

          context "fehb market" do
            it 'should have feature disabled' do
              expect(::EnrollRegistry.feature_enabled?("#{market.kind}_fetch_enrollment_minimum_participation_#{start_on.year}")).to be_falsey
            end
          end

          context "start on is on january 1st" do
            let(:effective_period) { start_on.beginning_of_year..start_on.end_of_year }

            it 'should return system default minimum ratio' do
              expect(application.employee_participation_ratio_minimum).to eq application.system_min_participation_default_for(effective_period.min)
            end
          end

          context "start on is not on january 1st" do
            let(:effective_period) { Date.new(start_on.year, 2, 1)..Date.new(start_on.year + 1, 1, 31) }

            it 'should return system default minimum ratio' do
              expect(application.employee_participation_ratio_minimum).to eq application.system_min_participation_default_for(effective_period.min)
            end
          end
        end

        context 'when resourcer registry feature enabled' do
          context "shop market" do
            it 'should have feature enabled' do
              expect(::EnrollRegistry.feature_enabled?("#{market.kind}_fetch_enrollment_minimum_participation_#{start_on.year}")).to be_truthy
            end
          end

          context "start on is not on january 1st" do
            let(:effective_period) { Date.new(start_on.year, 2, 1)..Date.new(start_on.year + 1, 1, 31) }
            let(:feature) { ::EnrollRegistry["#{market.kind}_fetch_enrollment_minimum_participation_#{start_on.year}"] }


            it 'should return minimum participation ratio from registry' do
              expect(application.employee_participation_ratio_minimum).to eq feature.settings(:fifty_percent_sponsor_fixed_percent_contribution_model).item
            end
          end

          context "contribution key missing" do
            let(:effective_period) { Date.new(start_on.year, 2, 1)..Date.new(start_on.year + 1, 1, 31) }
            let(:product_package) { double(benefit_kind: :aca_shop, contribution_model: double(key: nil))}

            it 'should return error' do
              result = ::EnrollRegistry["#{market.kind}_fetch_enrollment_minimum_participation_#{start_on.year}"] do
                {
                  product_package: product_package,
                  calender_year: application.start_on.year
                }
              end

              expect(result.failure?).to be_truthy
              expect(result.failure).to eq "contribution key missing."
            end

            it 'should return minimum participation ratio using system default' do
              expect(application.employee_participation_ratio_minimum).to eq application.system_min_participation_default_for(application.start_on)
            end
          end

          context "contribution key is different from registry setting" do
            let(:effective_period) { Date.new(start_on.year, 1, 1)..Date.new(start_on.year, 12, 31) }
            let(:product_package) { double(benefit_kind: :aca_shop, contribution_model: double(key: :list_bill_contribution_model))}

            it 'should return error' do
              result = ::EnrollRegistry["#{market.kind}_fetch_enrollment_minimum_participation_#{start_on.year}"] do
                {
                  product_package: product_package,
                  calender_year: application.start_on.year
                }
              end

              expect(result.failure?).to be_truthy
              expect(result.failure).to eq "unable to find minimum contribution for given contribution model."
            end

            it 'should return minimum participation ratio using system default' do
              expect(application.employee_participation_ratio_minimum).to eq application.system_min_participation_default_for(application.start_on)
            end
          end
        end
      end
    end

    RSpec.describe 'aasm_state#cancel', type: :model, :dbclean => :after_each, :if => ::EnrollRegistry[:aca_shop_market].enabled? do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application" do
        let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
      end
      let(:benefit_package)  { initial_application.benefit_packages.first }
      let(:benefit_group_assignment) {FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_package)}
      let(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: abc_profile.id) }
      let(:census_employee) do
        FactoryBot.create(:census_employee,
                          employer_profile: benefit_sponsorship.profile,
                          benefit_sponsorship: benefit_sponsorship,
                          benefit_group_assignments: [benefit_group_assignment])
      end
      let(:person)       { FactoryBot.create(:person, :with_family) }
      let!(:family)       { person.primary_family }
      let!(:hbx_enrollment) do
        hbx_enrollment = FactoryBot.create(:hbx_enrollment,
                                           :with_enrollment_members,
                                           :with_product,
                                           family: family,
                                           household: family.active_household,
                                           aasm_state: "coverage_selected",
                                           effective_on: initial_application.start_on,
                                           rating_area_id: initial_application.recorded_rating_area_id,
                                           sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
                                           sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
                                           benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
                                           employee_role_id: employee_role.id)
        hbx_enrollment.benefit_sponsorship = benefit_sponsorship
        hbx_enrollment.save!
        hbx_enrollment
      end

      context "cancelling effectuated application" do
        before do
          initial_application.cancel!
        end

        it "should cancel benefit application" do
          expect(initial_application.aasm_state).to eq :retroactive_canceled
        end

        it "should cancel associated enrollments" do
          hbx_enrollment.reload
          expect(hbx_enrollment.aasm_state).to eq "coverage_canceled"
        end

        it "should persit cancel reason to enrollment" do
          hbx_enrollment.reload
          expect(hbx_enrollment.terminate_reason).to eq "retroactive_canceled"
        end
      end

      context "cancelling non effectuated application" do
        before do
          initial_application.update_attributes(aasm_state: :enrollment_ineligible)
          initial_application.cancel!
        end

        it "should cancel benefit application" do
          expect(initial_application.aasm_state).to eq :canceled
        end

        it "should cancel associated enrollments" do
          hbx_enrollment.reload
          expect(hbx_enrollment.aasm_state).to eq "coverage_canceled"
        end

        it "should not persit cancel reason to enrollment" do
          hbx_enrollment.reload
          expect(hbx_enrollment.terminate_reason).to eq nil
        end
      end
    end

    RSpec.describe ".canceled?", type: :model, :dbclean => :after_each, :if => ::EnrollRegistry[:aca_shop_market].enabled? do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application" do
        let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
      end

      context "when application is canceled" do
        before do
          initial_application.cancel!
        end

        it "should return true" do
          expect(initial_application.canceled?).to eq true
        end
      end

      context "when application is active" do
        it "should return false" do
          expect(initial_application.canceled?).to eq false
        end
      end
    end
  end
end
#rubocop:enable Metrics/ModuleLength