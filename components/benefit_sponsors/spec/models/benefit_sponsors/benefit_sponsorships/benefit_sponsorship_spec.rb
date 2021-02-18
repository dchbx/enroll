require 'rails_helper'
require File.join(File.dirname(__FILE__), "..", "..", "..", "support/benefit_sponsors_site_spec_helpers")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe BenefitSponsorships::BenefitSponsorship, type: :model, dbclean: :after_each do
    let!(:previous_rating_area) { create_default(:benefit_markets_locations_rating_area, active_year: Date.current.year - 1) }
    let!(:previous_service_area) { create_default(:benefit_markets_locations_service_area, active_year: Date.current.year - 1) }
    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
    let!(:service_area) { create_default(:benefit_markets_locations_service_area) }
    let!(:next_rating_area) { create_default(:benefit_markets_locations_rating_area, active_year: Date.current.year + 1) }
    let!(:next_service_area) { create_default(:benefit_markets_locations_service_area, active_year: Date.current.year + 1) }
  
    let(:site) { ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market }
    let(:benefit_market)  { site.benefit_markets.first }

    let(:employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)        { employer_organization.employer_profile }

    describe "A new model instance" do
      it { is_expected.to be_mongoid_document }
      it { is_expected.to have_fields(:hbx_id, :profile_id)}
      it { is_expected.to have_field(:source_kind).of_type(Symbol).with_default_value_of(:self_serve)}
      it { is_expected.to embed_many(:broker_agency_accounts)}
      it { is_expected.to belong_to(:organization).as_inverse_of(:benefit_sponsorships)}

      context "built from a Profile" do
        subject { employer_profile.add_benefit_sponsorship }

        context "with all required arguments" do

          it "should reference the correct profile_id" do
            expect(subject.profile_id).to eq employer_profile.id
          end

          it "should pull attributes from the profile and it's backing organization instance" do
            expect(subject.benefit_market).to eq site.benefit_markets.first
          end

          it "should be valid" do
            subject.validate
            expect(subject).to be_valid
          end

          it "should be findable" do
            subject.save!
            expect(described_class.find(subject.id)).to eq subject
          end
        end
      end

      context "instantiated using .new" do
        let(:today)               { Date.today }
        let(:effective_begin_on)  { today.next_month.beginning_of_month }

        let(:params) do
          {
            profile: employer_profile,
            organization: employer_profile.organization,
          }
        end

        context "with no params" do
          subject { described_class.new }

          it "should not be valid", :agreggate_errors do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:profile_id].first).to match(/can't be blank/)
            expect(subject.errors[:organization].first).to match(/can't be blank/)
            expect(subject.errors[:benefit_market].first).to match(/can't be blank/)
          end
        end

        context "with no profile" do
          subject { described_class.new(params.except(:profile)) }

          it "should not be valid", :agreggate_errors do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.benefit_market).to eq site.benefit_markets.first
            expect(subject.errors[:profile_id].first).to match(/can't be blank/)
          end
        end

        context "with an organization different than profile's organization" do
          let(:invalid_organization)  { FactoryBot.build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }

          subject { described_class.new(params.except(:organization)) }

          before { subject.organization = invalid_organization }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:organization].first).to match(/must be profile's organization/)
          end
        end

        context "no params and a profile without organization or primary office location" do
          let(:profile_without_primary_office_location)   { BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new() }
          subject { described_class.new(profile: profile_without_primary_office_location) }

          it "should not be valid", :agreggate_errors do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:organization].first).to match(/can't be blank/)
            expect(subject.benefit_market).to be_nil
          end
        end

        context "and all arguments are valid" do
          subject { described_class.new(params) }

          it "should pull attributes from the profile and it's backing organization instance" do
            expect(subject.benefit_market).to eq site.benefit_markets.first
          end

          it "should be valid" do
            subject.validate
            expect(subject).to be_valid
          end

          it "should be findable" do
            subject.save!
            expect(described_class.find(subject.id)).to eq subject
          end
        end
      end
    end

    describe "Navigating BenefitSponsorship Predecessor/Successor linked list" do
      let(:linked_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:linked_profile)      { linked_organization.employer_profile }

      let(:node_a)      { described_class.new(profile: linked_profile) }
      let(:node_a1)     { described_class.new(profile: linked_profile, predecessor: node_a) }
      let(:node_a1a)    { described_class.new(profile: linked_profile, predecessor: node_a1) }
      let(:node_b1)     { described_class.new(profile: linked_profile, predecessor: node_a) }

      it "should manage predecessors", :aggregate_failures do
        expect(node_a1a.predecessor).to eq node_a1
        expect(node_a1.predecessor).to eq node_a
        expect(node_b1.predecessor).to eq node_a
        expect(node_a.predecessor).to eq nil
      end

      context "and the BenefitSponsorships are persisted" do
        before do
          node_a.save!
          node_a1.save!
          node_a1a.save!
          node_b1.save!
        end

        it "should maintain linked lists for successors", :aggregate_failures do
          expect(node_a.successors).to eq [node_a1, node_b1]
          expect(node_a1.successors).to eq [node_a1a]
        end
      end
    end

    describe "Working around validating model factory" do
      context "when benefit sponsor has profile and organization" do
        let(:valid_build_benefit_sponsorship)  { FactoryBot.build(:benefit_sponsors_benefit_sponsorship, :with_full_package) }
        let(:valid_create_benefit_sponsorship) { FactoryBot.create(:benefit_sponsors_benefit_sponsorship, :with_market_profile)}

        it "with_full_package build should be valid" do
          expect(valid_build_benefit_sponsorship.valid?).to be_truthy
        end

        it "with_market_profile create should be valid" do
          expect(valid_create_benefit_sponsorship.valid?).to be_truthy
        end
      end

      context "when benefit sponsorship is CCA SHOP employer" do
        let(:cca_employer_organization)   { FactoryBot.build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
        let(:cca_profile)                 { cca_employer_organization.employer_profile  }
        let(:benefit_sponsorship)         { cca_profile.add_benefit_sponsorship }

        it "should be valid" do
          expect(benefit_sponsorship.valid?).to be true
        end
      end
    end

    describe "Finding a BenefitSponsorCatalog" do
      let(:benefit_sponsorship) do
        sponsorship = employer_profile.add_benefit_sponsorship
        sponsorship.save
        sponsorship
      end
      let(:next_year)                           { Date.today.year + 1 }
      let(:application_period_next_year)        { (Date.new(next_year,1,1))..(Date.new(next_year,12,31)) }
      let!(:issuer_profile)  { FactoryBot.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}
      let!(:benefit_market_catalog_next_year)   { FactoryBot.create(:benefit_markets_benefit_market_catalog, :with_product_packages, issuer_profile: issuer_profile, benefit_market: benefit_market, application_period: application_period_next_year) }

      before { benefit_market.add_benefit_market_catalog(benefit_market_catalog_next_year) }

      it "should belong to the same site and benefit_market and include benefit_market_catalog_next_year", :aggregate_failures do
        expect(benefit_sponsorship.profile.organization.site).to eq benefit_market.site
        expect(benefit_sponsorship.benefit_market).to eq benefit_market
        expect(benefit_market.benefit_market_catalogs.size).to eq 1
        expect(benefit_market.benefit_market_catalogs.first).to eq benefit_market_catalog_next_year
      end

      context "given an effective_date during next year's application period" do
        let(:effective_date)  { benefit_market.benefit_market_catalogs.first.application_period.min }

        # before { benefit_market.benefit_market_catalogs = benefit_market_catalogs }
        it "should find a benefit_market_catalog" do
          expect(benefit_sponsorship.benefit_sponsor_catalog_for(effective_date)).to be_an_instance_of(BenefitMarkets::BenefitSponsorCatalog)
        end
      end

      context "given an effective_date in future, undefined application period" do
        let(:future_effective_date)  { Date.new((next_year + 2),1,1) }

        it "should not find a benefit_market_catalog" do
          expect{benefit_sponsorship.benefit_sponsor_catalog_for(future_effective_date)}.to raise_error(/benefit_market_catalog not found for effective date: #{future_effective_date}/)
        end
      end
    end

    describe "Working with subclassed parent Profiles" do
      context "using sic_code helper method" do
        let(:cca_employer_organization)   { FactoryBot.build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
        let(:cca_employer_profile)        { cca_employer_organization.employer_profile }
        let(:sic_code)                    { "1110" }

        context "on cca_employer_profile with attribute defined but not set" do
          before { cca_employer_profile.sic_code = nil; cca_employer_profile.add_benefit_sponsorship }

          it "cca_employer_profile should have exactly one benefit_sponsorship" do
            expect(cca_employer_profile.benefit_sponsorships.size).to eq 1
          end

          it "empployer_profile sic_code should be set" do
            expect(cca_employer_profile.sic_code).to eq nil
          end

          it "should return correct value" do
            expect(cca_employer_profile.benefit_sponsorships[0].sic_code).to be_nil
          end
        end

        context "on cca_employer_profile with attribute defined" do
          before { cca_employer_profile.sic_code = sic_code; cca_employer_profile.add_benefit_sponsorship }

          it "should return correct value" do
            expect(cca_employer_profile.benefit_sponsorships[0].sic_code).to eq sic_code
          end
        end
      end

      # TODO: Before deleting this make sure you move this spec to appropriate model
      # context "using rating_area helper method" do
      #   let(:rating_area)                   { ::BenefitMarkets::Locations::RatingArea.new }
      #   let(:profile_with_rating_area)      { BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new(rating_area: rating_area ) }
      #   let(:profile_with_nil_rating_area)  { BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new }
      #   let(:profile_without_rating_area)   { BenefitSponsors::Organizations::AcaShopDcEmployerProfile.new }

      #   context "on profile without attribute defined" do
      #     subject { described_class.new(profile: profile_without_rating_area) }

      #     it "should not return value" do
      #       expect(subject.rating_area).to be_nil
      #     end
      #   end

      #   context "on profile with attribute defined but not set" do
      #     subject { described_class.new(profile: profile_with_nil_rating_area) }

      #     it "should return correct value" do
      #       expect(subject.rating_area).to be_nil
      #     end
      #   end

      #   context "on profile with attribute defined" do
      #     subject { described_class.new(profile: profile_with_rating_area) }

      #     it "should return correct value" do
      #       expect(subject.rating_area).to eq rating_area
      #     end
      #   end

      # end
    end

    describe "Transitioning a BenefitSponsorship through Initial Application Workflow States" do
      let(:benefit_sponsorship)                 { employer_profile.add_benefit_sponsorship }
      let(:this_year)                           { Date.today.year }
      let(:benefit_sponsor_catalog) { FactoryBot.create(:benefit_markets_benefit_sponsor_catalog, service_areas: [service_area]) }
      let(:service_area) { create_default(:benefit_markets_locations_service_area) }
      let(:benefit_application) do
        build(
          :benefit_sponsors_benefit_application,
          benefit_sponsorship: benefit_sponsorship,
          recorded_service_areas: benefit_sponsorship.service_areas,
          benefit_sponsor_catalog: benefit_sponsor_catalog
        )
      end

      context "and system date is set to today" do
        before { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

        it "benefit_sponsorship should initialize in state: :applicant" do
          expect(benefit_sponsorship.aasm_state).to eq :applicant
        end

        it "benefit_application should initialize in state: :draft" do
          expect(benefit_application.aasm_state).to eq :draft
        end

        context "and a benefit application is submitted" do
          context "and benefit application is valid" do
            before { benefit_application.approve_application! }

            it "benefit_sponsorship should remain in applicant state" do
              expect(benefit_sponsorship.aasm_state).to eq :applicant
            end

            context "and open enrollment period begins" do
              before {
                TimeKeeper.set_date_of_record_unprotected!(benefit_application.open_enrollment_period.min)
                benefit_application.begin_open_enrollment!
              }

              after {
                TimeKeeper.set_date_of_record_unprotected!(Date.today)
              }

              it "should remain in applicant state" do
                expect(benefit_sponsorship.aasm_state).to eq :applicant
              end

              context "and open enrollment period ends" do
                before {
                  TimeKeeper.set_date_of_record_unprotected!(benefit_application.open_enrollment_period.max)
                  benefit_application.end_open_enrollment!
                }

                after {
                  TimeKeeper.set_date_of_record_unprotected!(Date.today)
                }

                it "benefit_sponsorship should remain in applicant state" do
                  expect(benefit_sponsorship.aasm_state).to eq :applicant
                end


                context "and binder is paid for initial employers" do
                  before { benefit_application.credit_binder! }

                  it "benefit_sponsorship should transition to state: :binder_paid" do
                    expect(benefit_sponsorship.aasm_state).to eq :applicant
                  end

                  it "benefit_application should remain in applicant state" do
                    expect(benefit_application.aasm_state).to eq :binder_paid
                  end

                  context "and effective period begins" do
                    before {
                      TimeKeeper.set_date_of_record_unprotected!(benefit_application.effective_period.min)
                      benefit_application.activate_enrollment!
                    }

                    after {
                      TimeKeeper.set_date_of_record_unprotected!(Date.today)
                    }

                    it "benefit_sponsorship should transition to state: :active" do
                      expect(benefit_sponsorship.aasm_state).to eq :active
                    end

                    it "benefit_application should transition to state: :active" do
                      expect(benefit_application.aasm_state).to eq :active
                    end
                  end
                end
              end
            end
          end

          context "and benefit application is invalid" do
            before { benefit_application.review_application! }

            it "benefit_application should transition to state: :pending" do
              expect(benefit_application.aasm_state).to eq :pending
            end

            it "benefit_sponsorship should remain :applicant" do
              expect(benefit_sponsorship.aasm_state).to eq :applicant
            end

            context "and it's denied by HBX" do
              before { benefit_application.deny_application! }

              it "benefit_application should transition to state: :denied" do
                expect(benefit_application.aasm_state).to eq :denied
              end

              it "benefit_sponsorship should transition to state: :initial_application_denied" do
                expect(benefit_sponsorship.aasm_state).to eq :denied
              end
            end

            context "and it's approved by HBX" do
              before { benefit_application.approve_application! }

              it "benefit_application should transition to state: :approved" do
                expect(benefit_application.aasm_state).to eq :approved
              end

              it "benefit_sponsorship should remain in applicant" do
                expect(benefit_sponsorship.aasm_state).to eq :applicant
              end
            end

            context "and it's reverted by HBX" do
              before { benefit_application.revert_application }

              it "benefit_application should transition to state: :draft" do
                expect(benefit_application.aasm_state).to eq :draft
              end

              it "benefit_sponsorship should transition to state: :applicant" do
                expect(benefit_sponsorship.aasm_state).to eq :applicant
              end
            end
          end
        end
      end
    end

    describe "most_recent_benefit_application", :dbclean => :after_each do
      let(:benefit_sponsorship)                 { employer_profile.add_benefit_sponsorship }

      let!(:imported_benefit_application) do
        FactoryBot.create(
          :benefit_sponsors_benefit_application,
          benefit_sponsorship: benefit_sponsorship,
          recorded_service_areas: benefit_sponsorship.service_areas,
          aasm_state: :imported
        )
      end

      context "when employer has no benefit application" do

        it "should not return benefit_application" do
          expect(benefit_sponsorship.most_recent_benefit_application).to eq nil
        end
      end

      context "when employer with no benefit application" do
        before { benefit_sponsorship.benefit_applications = []}

        it "should not return benefit_application" do
          expect(benefit_sponsorship.most_recent_benefit_application).to eq nil
        end
      end

      context "when employer with imported & submitted benefit application" do

        let!(:submitted_benefit_application) do
          FactoryBot.create(
            :benefit_sponsors_benefit_application,
            benefit_sponsorship: benefit_sponsorship,
            recorded_service_areas: benefit_sponsorship.service_areas,
            aasm_state: :approved
          )
        end

        it "should return submitted_benefit_application" do
          expect(benefit_sponsorship.most_recent_benefit_application).to eq submitted_benefit_application
        end
      end
    end

    describe "submitted_benefit_application", :dbclean => :after_each do
      let(:benefit_sponsorship)             { employer_profile.add_benefit_sponsorship }
      let!(:imported_benefit_application) do
        FactoryBot.create(
          :benefit_sponsors_benefit_application,
          benefit_sponsorship: benefit_sponsorship,
          recorded_service_areas: benefit_sponsorship.service_areas,
          aasm_state: :imported
        )
      end
      context "when an employer has imported benefit application" do
        it "should return imported benefit application" do
          benefit_sponsorship.update_attributes!(source_kind: :conversion)
          expect(benefit_sponsorship.submitted_benefit_application).to eq imported_benefit_application
        end
      end

      context "when employer with imported & active benefit application" do
        let!(:active_benefit_application) do
          FactoryBot.create(
            :benefit_sponsors_benefit_application,
            benefit_sponsorship: benefit_sponsorship,
            recorded_service_areas: benefit_sponsorship.service_areas, aasm_state: :active
          )
        end
        it "should return active benefit application" do
          benefit_sponsorship.update_attributes!(source_kind: :conversion)
          expect(benefit_sponsorship.submitted_benefit_application).to eq active_benefit_application
        end
      end
    end

    describe "active_imported_benefit_application", :dbclean => :after_each do
      let(:benefit_sponsorship) { employer_profile.add_benefit_sponsorship }

      context "when employer with active imported benefit application" do
        let!(:active_imported_benefit_application) do
          FactoryBot.create(
            :benefit_sponsors_benefit_application,
            benefit_sponsorship: benefit_sponsorship,
            recorded_service_areas: benefit_sponsorship.service_areas, aasm_state: :imported
          )
        end

        it "should return active imported benefit application" do
          benefit_sponsorship.update_attributes!(source_kind: :conversion)
          expect(benefit_sponsorship.active_imported_benefit_application).to eq active_imported_benefit_application
        end
      end

      context "when employer with expired imported benefit application" do
        let(:effective_on) { TimeKeeper.date_of_record - 2.years}
        let(:effective_period) { effective_on..(effective_on.next_year.prev_day) }
        let(:expired_imported_benefit_application) do
          FactoryBot.create(
            :benefit_sponsors_benefit_application,
            benefit_sponsorship: benefit_sponsorship,
            recorded_service_areas: benefit_sponsorship.service_areas,
            aasm_state: :imported,
            effective_period: effective_period
          )
        end

        it "should return nil" do
          benefit_sponsorship.update_attributes!(source_kind: :conversion)
          expect(benefit_sponsorship.active_imported_benefit_application).to eq nil
        end
      end
    end

    describe "dt_display_benefit_application", :dbclean => :after_each do
      let(:benefit_sponsorship)             { employer_profile.add_benefit_sponsorship }

      context "when an employer has renewing draft benefit application" do
        let!(:draft_benefit_application) do
          FactoryBot.create(
            :benefit_sponsors_benefit_application,
            benefit_sponsorship: benefit_sponsorship,
            recorded_service_areas: benefit_sponsorship.service_areas,
            aasm_state: :draft
          )
        end

        it "should return draft benefit application" do
          benefit_sponsorship.update_attributes!(source_kind: :conversion)
          expect(benefit_sponsorship.dt_display_benefit_application).to eq draft_benefit_application
        end
      end

      context "when employer with renewing draft & active benefit application" do
        let(:active_app_start_on)  { TimeKeeper.date_of_record.beginning_of_month.prev_month }
        let(:draft_app_start_on)  { TimeKeeper.date_of_record.beginning_of_month + 2.months }

        let!(:active_benefit_application) do
          FactoryBot.create(
            :benefit_sponsors_benefit_application,
            benefit_sponsorship: benefit_sponsorship,
            effective_period: active_app_start_on..active_app_start_on.next_year.prev_day,
            recorded_service_areas: benefit_sponsorship.service_areas, aasm_state: :active
          )
        end

        let!(:renewing_benefit_application) do
          FactoryBot.create(
            :benefit_sponsors_benefit_application,
            benefit_sponsorship: benefit_sponsorship,
            effective_period: draft_app_start_on..draft_app_start_on.next_year.prev_day,
            recorded_service_areas: benefit_sponsorship.service_areas,
            aasm_state: :draft
          )
        end
        it "should return renewing draft benefit application" do
          benefit_sponsorship.update_attributes!(source_kind: :conversion)
          expect(benefit_sponsorship.dt_display_benefit_application).to eq renewing_benefit_application
        end
      end

      context "when employer with active benefit application" do
        let!(:active_benefit_application) do
          FactoryBot.create(
            :benefit_sponsors_benefit_application,
            benefit_sponsorship: benefit_sponsorship,
            recorded_service_areas: benefit_sponsorship.service_areas, aasm_state: :active
          )
        end

        it "should return active benefit application" do
          benefit_sponsorship.update_attributes!(source_kind: :conversion)
          expect(benefit_sponsorship.dt_display_benefit_application).to eq active_benefit_application
        end
      end
    end

    describe "Scopes", :dbclean => :after_each do
      let!(:rating_area)                    { FactoryBot.create(:benefit_markets_locations_rating_area)  }
      let!(:service_area)                    { FactoryBot.create(:benefit_markets_locations_service_area)  }
      let(:this_year)                       { TimeKeeper.date_of_record.year }

      let(:march_effective_date)            { Date.new(this_year,3,1) }
      let(:march_open_enrollment_begin_on)  { march_effective_date - 1.month }
      let(:march_open_enrollment_end_on)    { march_open_enrollment_begin_on + 9.days }

      let(:april_effective_date)            { Date.new(this_year,4,1) }
      let(:april_open_enrollment_begin_on)  { april_effective_date - 1.month }
      let(:april_open_enrollment_end_on)    { april_open_enrollment_begin_on + 9.days }

      let(:initial_application_state)       { :active }
      let(:renewal_application_state)       { :enrollment_open }
      let(:sponsorship_state)               { :active }
      let(:renewal_current_application_state) { :active }


      let!(:march_sponsors) do
        create_list(
          :benefit_sponsors_benefit_sponsorship,
          3,
          :with_organization_cca_profile,
          :with_initial_benefit_application,
          initial_application_state: initial_application_state,
          default_effective_period: (march_effective_date..(march_effective_date + 1.year - 1.day)),
          site: site,
          aasm_state: sponsorship_state
        )
      end

      let!(:april_sponsors) do
        create_list(
          :benefit_sponsors_benefit_sponsorship,
          2,
          :with_organization_cca_profile,
          :with_initial_benefit_application,
          initial_application_state: initial_application_state,
          default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)),
          site: site,
          aasm_state: sponsorship_state
        )
      end

      let!(:april_renewal_sponsors) do
        create_list(
          :benefit_sponsors_benefit_sponsorship,
          2,
          :with_organization_cca_profile,
          :with_renewal_benefit_application,
          initial_application_state: renewal_current_application_state,
          renewal_application_state: renewal_application_state,
          default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)),
          site: site,
          aasm_state: :active
        )
      end

      let(:current_date)                    { Date.today }

      before { TimeKeeper.set_date_of_record_unprotected!(current_date) }

      subject { BenefitSponsors::BenefitSponsorships::BenefitSponsorship }

      context '.may_begin_open_enrollment?' do
        let(:initial_application_state) { :approved }

        it "should find sponsorships with application in approved state and matching open enrollment begin date" do
          expect(subject.may_begin_open_enrollment?(april_open_enrollment_begin_on).size).to eq (march_sponsors.size + april_sponsors.size)
          expect(subject.may_begin_open_enrollment?(april_open_enrollment_begin_on).to_a.sort).to eq ((march_sponsors + april_sponsors).sort)
        end
      end

      context '.may_end_open_enrollment?' do
        context 'applications that are under enrollment_open state' do 
          let(:initial_application_state) { :enrollment_open }
          let(:renewal_application_state) { :enrollment_open }

          it "matching open enrollment end on date should be returned" do
            expect(subject.may_end_open_enrollment?(april_open_enrollment_end_on.next_day).size).to eq (march_sponsors.size + april_sponsors.size + april_renewal_sponsors.size)
            expect(subject.may_end_open_enrollment?(april_open_enrollment_end_on.next_day).to_a.sort).to eq ((march_sponsors + april_sponsors + april_renewal_sponsors).sort)
          end
        end

        context 'applications that are under enrollment_extended state' do 
          let(:initial_application_state) { :enrollment_extended }
          let(:renewal_application_state) { :enrollment_extended }

          it "matching open enrollment end on date should be returned" do
            expect(subject.may_end_open_enrollment?(april_open_enrollment_end_on.next_day).size).to eq (march_sponsors.size + april_sponsors.size + april_renewal_sponsors.size)
            expect(subject.may_end_open_enrollment?(april_open_enrollment_end_on.next_day).to_a.sort).to eq ((march_sponsors + april_sponsors + april_renewal_sponsors).sort)
          end
        end
      end

      context '.may_begin_benefit_coverage?' do
        let(:initial_application_state) { :enrollment_eligible }
        let(:renewal_application_state) { :enrollment_eligible }

        it "should find sponsorships with application in enrollment_eligible state and matching effective period begin date" do
          expect(subject.may_begin_benefit_coverage?(march_effective_date).size).to eq (march_sponsors.size)
          expect(subject.may_begin_benefit_coverage?(march_effective_date).to_a.sort).to eq (march_sponsors.sort)

          expect(subject.may_begin_benefit_coverage?(april_effective_date).size).to eq (march_sponsors.size + april_sponsors.size + april_renewal_sponsors.size)
          expect(subject.may_begin_benefit_coverage?(april_effective_date).to_a.sort).to eq ((march_sponsors + april_sponsors + april_renewal_sponsors).sort)
        end
      end

      context '.may_end_benefit_coverage?' do
        let(:initial_application_state) { :active }
        let(:renewal_application_state) { :active }
        let(:renewal_current_application_state) { :expired }

        it "should find sponsorships with application in active state and matching effective period end date" do
          expect(subject.may_end_benefit_coverage?(march_effective_date.next_year).size).to eq (march_sponsors.size)
          expect(subject.may_end_benefit_coverage?(march_effective_date.next_year).to_a.sort).to eq (march_sponsors.sort)

          expect(subject.may_end_benefit_coverage?(april_effective_date.next_year).size).to eq (march_sponsors.size + april_sponsors.size + april_renewal_sponsors.size)
          expect(subject.may_end_benefit_coverage?(april_effective_date.next_year).to_a.sort).to eq ((march_sponsors + april_sponsors + april_renewal_sponsors).sort)
        end
      end

      context '.may_renew_application?' do
        let(:initial_application_state) { :active }

        it "should find sponsorships with application in active state and matching effective period begin date" do
          expect(subject.may_renew_application?(april_effective_date.prev_day).size).to eq (april_renewal_sponsors.size)
          expect(subject.may_renew_application?(april_effective_date.prev_day).to_a.sort).to eq (april_renewal_sponsors.sort)
        end
      end

      context '.may_terminate_benefit_coverage?' do

        it "should find sponsorships with application in termination_pending state and matching terminated_on date" do
        end
      end

      context '.may_transmit_initial_enrollment?' do
        let(:initial_application_state) { :binder_paid }
        let(:sponsorship_state) { :applicant }

        let!(:april_ineligible_initial_sponsors) do
          create_list(
            :benefit_sponsors_benefit_sponsorship,
            2,
            :with_organization_cca_profile,
            :with_initial_benefit_application,
            initial_application_state: :enrollment_ineligible,
            default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)),
            site: site,
            aasm_state: sponsorship_state
          )
        end

        let!(:april_wrong_sponsorship_initial_sponsors) do
          create_list(
            :benefit_sponsors_benefit_sponsorship,
            2,
            :with_organization_cca_profile,
            :with_initial_benefit_application,
            initial_application_state: :enrollment_ineligible,
            default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)),
            site: site,
            aasm_state: sponsorship_state
          )
        end

        it "should fetch only valid initial applications" do 
          applications = subject.may_transmit_initial_enrollment?(april_effective_date)

          expect((applications & april_sponsors).sort).to eq april_sponsors.sort
          expect(applications & april_ineligible_initial_sponsors).to be_empty
          expect(applications & april_wrong_sponsorship_initial_sponsors).to be_empty
        end

        context 'initial_enrollment and sponsorship with active state' do

          let(:initial_application_state) { :active }
          let(:sponsorship_state) { :active }

          let!(:april_ineligible_initial_sponsors) do
            create_list(:benefit_sponsors_benefit_sponsorship, 2, :with_organization_cca_profile, :with_initial_benefit_application,
                        initial_application_state: :enrollment_ineligible,
                        default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)),
                        site: site, aasm_state: sponsorship_state)

          end

          let!(:april_wrong_sponsorship_initial_sponsors) do
            create_list(:benefit_sponsors_benefit_sponsorship, 2, :with_organization_cca_profile, :with_initial_benefit_application,
                        initial_application_state: :enrollment_ineligible,
                        default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)),
                        site: site, aasm_state: :initial_enrollment_ineligible)

          end

          it "should fetch only valid initial applications" do
            applications = subject.may_transmit_initial_enrollment?(april_effective_date)

            expect((applications & april_sponsors).sort).to eq april_sponsors.sort
            expect(applications & april_ineligible_initial_sponsors).to be_empty
            expect(applications & april_wrong_sponsorship_initial_sponsors).to be_empty
          end
        end

        context 'initial_enrollment with matching workflow state transition ' do
          let!(:april_eligible_benefit_sponsorhip_1)  { april_sponsors[0]}
          let!(:april_eligible_benefit_sponsorhip_2)  { april_sponsors[1]}
          let(:transition_at) {TimeKeeper.start_of_exchange_day_from_utc(TimeKeeper.date_of_record)}
          let(:transition_at_2) {TimeKeeper.start_of_exchange_day_from_utc(TimeKeeper.date_of_record - 1.day)}
          let!(:create_workflow_state_transition) do
            april_eligible_benefit_sponsorhip_1.benefit_applications.first.workflow_state_transitions.create(from_state: :enrollment_closed, to_state: :binder_paid, transition_at: transition_at)
            april_eligible_benefit_sponsorhip_2.benefit_applications.first.workflow_state_transitions.create(from_state: :enrollment_closed, to_state: :binder_paid, transition_at: transition_at_2)
          end

          it "should fetch only valid initial applications with matching transition state and time" do
            applications = subject.may_transmit_initial_enrollment?(april_effective_date, transition_at)
            expect(applications & april_sponsors).to eq [april_eligible_benefit_sponsorhip_1]
          end

          it "should fetch only valid initial applications with matching transition state and time" do
            applications = subject.may_transmit_initial_enrollment?(april_effective_date, transition_at_2)
            expect(applications & april_sponsors).to eq [april_eligible_benefit_sponsorhip_2]
          end
        end
      end

      context '.may_transmit_renewal_enrollment?' do

        let(:renewal_application_state) { :enrollment_eligible }

        let!(:april_ineligible_renewal_sponsors) do
          create_list(
            :benefit_sponsors_benefit_sponsorship,
            2,
            :with_organization_cca_profile,
            :with_renewal_benefit_application,
            initial_application_state: initial_application_state,
            renewal_application_state: :enrollment_ineligible,
            default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)),
            site: site,
            aasm_state: :active
          )
        end

        let!(:april_wrong_sponsorship_renewal_sponsors) do
          create_list(
            :benefit_sponsors_benefit_sponsorship,
            1,
            :with_organization_cca_profile,
            :with_renewal_benefit_application,
            initial_application_state: initial_application_state,
            renewal_application_state: :enrollment_eligible,
            default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)),
            site: site,
            aasm_state: :applicant
          )
        end

        it "should fetch only valid renewal applications" do
          april_wrong_sponsorship_renewal_sponsors.each {|bs| bs.renewal_benefit_application.update_attributes(predecessor_id: nil)}
          applications = subject.may_transmit_renewal_enrollment?(april_effective_date)

          expect(applications & april_renewal_sponsors).to eq april_renewal_sponsors
          expect(applications & april_ineligible_renewal_sponsors).to eq april_ineligible_renewal_sponsors
          expect(applications & april_wrong_sponsorship_renewal_sponsors).to be_empty
        end

        context 'renewal_enrollment with matching workflow state transition' do
          let!(:april_renewal_eligible_benefit_sponsorhip_1)  { april_renewal_sponsors[0]}
          let!(:april_renewal_eligible_benefit_sponsorhip_2)  { april_renewal_sponsors[1]}

          let!(:april_renewal_app_1)  { april_renewal_eligible_benefit_sponsorhip_1.benefit_applications.where(aasm_state: :enrollment_eligible).first}
          let!(:april_renewal_app_2)  { april_renewal_eligible_benefit_sponsorhip_2.benefit_applications.where(aasm_state: :enrollment_eligible).first}
          let(:transition_at) {TimeKeeper.start_of_exchange_day_from_utc(TimeKeeper.date_of_record)}
          let(:transition_at_2) {TimeKeeper.start_of_exchange_day_from_utc(TimeKeeper.date_of_record - 1.day)}

          let!(:create_workflow_state_transition) do
            april_renewal_app_1.workflow_state_transitions.create(from_state: :enrollment_closed, to_state: :enrollment_eligible, transition_at: transition_at)
            april_renewal_app_2.workflow_state_transitions.create(from_state: :enrollment_closed, to_state: :enrollment_eligible, transition_at: transition_at_2)
          end

          it "should fetch only valid renewal applications with matching transition state and time" do
            applications = subject.may_transmit_renewal_enrollment?(april_effective_date, TimeKeeper.date_of_record)
            expect(applications & april_renewal_sponsors).to eq [april_renewal_eligible_benefit_sponsorhip_1]
          end

          it "should fetch only valid renewal applications with matching transition state and time" do
            applications = subject.may_transmit_renewal_enrollment?(april_effective_date, transition_at_2)
            expect(applications & april_renewal_sponsors).to eq [april_renewal_eligible_benefit_sponsorhip_2]
          end
        end
      end

      context '.may_auto_submit_application?' do

      end

      context '.may_transition_as_initial_ineligible?' do 
        let(:initial_application_state) { :enrollment_closed }
        let(:renewal_application_state) { :enrollment_closed }
        let(:april_enrollment_elgible_sponsor) { april_sponsors[0] }
        let(:april_ineligible_sponsors) { april_sponsors.select{|sponsor| sponsor != april_enrollment_elgible_sponsor } }

        before do
          april_enrollment_elgible_sponsor.benefit_applications.first.credit_binder!
        end

        it "should find initial sponsorships with applications in enrollment_closed state and matching effective date" do
          expect(subject.may_transition_as_initial_ineligible?(march_effective_date).size).to eq (march_sponsors.size)
          expect(subject.may_transition_as_initial_ineligible?(march_effective_date).to_a.sort).to eq (march_sponsors.sort)
          expect(subject.may_transition_as_initial_ineligible?(april_effective_date).size).to eq (april_ineligible_sponsors.size)
          expect(subject.may_transition_as_initial_ineligible?(april_effective_date).to_a.sort).to eq (april_ineligible_sponsors.sort)
        end
      end

      context '.may_cancel_ineligible_application?' do
        let(:initial_application_state) { :enrollment_ineligible }
        let(:renewal_application_state) { :enrollment_ineligible }
        let(:april_enrollment_elgible_sponsor) { april_sponsors[0] }
        let(:april_ineligible_sponsors) { april_sponsors.select{|sponsor| sponsor != april_enrollment_elgible_sponsor } }

        before do
          april_enrollment_elgible_sponsor.benefit_applications.first.update(aasm_state: :enrollment_closed)
          april_enrollment_elgible_sponsor.benefit_applications.first.credit_binder!
        end

        it "should find sponsorships with application in enrollment_eligible state and matching effective period begin date" do
          expect(subject.may_cancel_ineligible_application?(march_effective_date).size).to eq (march_sponsors.size)
          expect(subject.may_cancel_ineligible_application?(march_effective_date).to_a.sort).to eq (march_sponsors.sort)

          expect(subject.may_cancel_ineligible_application?(april_effective_date).size).to eq (april_ineligible_sponsors.size + april_renewal_sponsors.size)
          expect(subject.may_cancel_ineligible_application?(april_effective_date).to_a.sort).to eq ((april_ineligible_sponsors + april_renewal_sponsors).sort)
        end
      end

      context 'non-binder paid applications count' do
        let(:initial_application_state) { :enrollment_closed }

        it "should find sponsorships with application in enrollment_closed state and matching effective period begin date" do
          expect(subject.may_cancel_ineligible_application?(march_effective_date).size).to eq march_sponsors.size
          march_sponsors[0].benefit_applications.first.credit_binder!
          expect(subject.may_cancel_ineligible_application?(march_effective_date).size).to eq march_sponsors.size - 1
        end
      end
    end

    describe "Finding BenefitApplications" do

      context "and one benefit_application is unsubmitted" do
        it "most_recent_benefit_application should find the benefit_application"
        it "current_benefit_application should find the benefit_application"
        it "should not find a renewal_benefit_application"
        it "should not find an active_benefit_application"
        it "should not find a renewing_submitted_application"

        context "and the benefit_application is effectuated" do
          it "active_benefit_application should the benefit_application"

          context "and a renewal_benefit_application is instantiated" do
            it "should find a renewal_benefit_application"
            it "most_recent_benefit_application should find the renewal_benefit_application"
            it "active_benefit_application should find the effectuated benefit_application"
            it "current_benefit_application should find the effectuated benefit_application"
            it "should not find a renewing_submitted_application"

            context "and the renewal_benefit_application is submitted" do
              it "renewing_submitted_application should find the renewal_benefit_application"

            end

            context "and the renewal_benefit_application is effectuated" do
              it "should not find a renewal_benefit_application"
              it "active_benefit_application should find the effectuated renewal_benefit_application"
              it "current_benefit_application should find the effectuated renewal_benefit_application"
            end
          end
        end

      end
    end

    describe "Benefit Application Open Enrollment Extension", :dbclean => :after_each do
      let(:aasm_state) { :active }
      let(:sponsorship_state)               { :active }

      let(:this_year)                       { TimeKeeper.date_of_record.year }
      let(:april_effective_date)            { Date.new(this_year,4,1) }
      let(:april_open_enrollment_begin_on)  { april_effective_date - 1.month }
      let(:april_open_enrollment_end_on)    { april_open_enrollment_begin_on + 9.days }

      let!(:april_sponsor) do
        create(
          :benefit_sponsors_benefit_sponsorship,
          :with_organization_cca_profile,
          :with_initial_benefit_application,
          default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)),
          site: site,
          aasm_state: sponsorship_state,
          initial_application_state: aasm_state
        )
      end

      let(:april_application) { april_sponsor.benefit_applications.detect{|app| app.start_on == april_effective_date} }

 
      context '.oe_extendable_benefit_applications' do

        let(:current_date)  { Date.new(this_year, 4, 10) }
        before { TimeKeeper.set_date_of_record_unprotected!(current_date) }

        after { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

        context "when overlapping benefit application present with status as" do
          let(:new_effective_date)            { Date.new(this_year,4,1) }

          let!(:new_application) do
            create(
              :benefit_sponsors_benefit_application,
              benefit_sponsorship: april_sponsor,
              effective_period: (new_effective_date..(new_effective_date + 1.year - 1.day)),
              aasm_state: :canceled
            )
          end

          context "terminted" do
            let(:aasm_state) { :terminated }

            it "should not return application for enrollment extension" do
              expect(april_sponsor.oe_extendable_benefit_applications).to be_empty
            end 
          end

          context "approved" do
            let(:aasm_state) { :approved }

            it "should not return application for enrollment extension" do 
              expect(april_sponsor.oe_extendable_benefit_applications).to be_empty
            end
          end

          context "enrollment_extended" do
            let(:aasm_state) { :enrollment_extended }

            it "should return only already extended application" do 
              expect(april_sponsor.oe_extendable_benefit_applications).to be_present
              expect(april_sponsor.oe_extendable_benefit_applications).to eq [april_application]
            end
          end

          context "expired" do
            let(:aasm_state) { :expired }

            it "should not return application for enrollment extension" do
              expect(april_sponsor.oe_extendable_benefit_applications).to be_empty
            end
          end

          context "draft" do
            let(:aasm_state) { :draft }

            it "should return application for enrollment extension" do 
              expect(april_sponsor.oe_extendable_benefit_applications).to be_present
              expect(april_sponsor.oe_extendable_benefit_applications).to eq [new_application]
            end
          end
        end

        context "when overlapping benefit application not present" do

          let(:april_effective_date)          { Date.new(this_year - 1,4,1) }
          let(:new_effective_date)            { Date.new(this_year,5,1) }

          let!(:new_application) do
            create(
              :benefit_sponsors_benefit_application,
              benefit_sponsorship: april_sponsor,
              effective_period: (new_effective_date..(new_effective_date + 1.year - 1.day)),
              aasm_state: :canceled
            )
          end

          it "should return may application for enrollment extension" do
            expect(april_sponsor.oe_extendable_benefit_applications).to be_present
            expect(april_sponsor.oe_extendable_benefit_applications).to eq [new_application]
          end
        end 
      end

      context '.oe_extended_applications' do

        before {
          allow(april_sponsor).to receive(:open_enrollment_period_for).and_return(april_open_enrollment_begin_on..april_open_enrollment_end_on)
          TimeKeeper.set_date_of_record_unprotected!(april_open_enrollment_end_on + 1.day)
        }

        after { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

        context "when open enrollment extended application present" do
          let(:aasm_state) { :enrollment_extended }

          context "and monthly open enrollment end date not passed" do
            let(:aasm_state) { :terminated }
            let(:current_date)  { april_sponsor.open_enrollment_period_for(april_effective_date).max - 2.days }

            it "should not return application for close of open enrollment" do
              expect(april_sponsor.oe_extended_applications).to be_empty
            end
          end

          context "and monthly open enrollment end date reached" do
            let(:aasm_state) { :terminated }
            let(:current_date)  { april_sponsor.open_enrollment_period_for(april_effective_date).max }

            it "should not return application for close of open enrollment" do
              expect(april_sponsor.oe_extended_applications).to be_empty
            end
          end

          context "and monthly open enrollment end date passed" do
            let(:aasm_state) { :terminated }
            let(:current_date)  { april_sponsor.open_enrollment_period_for(april_effective_date).max + 2.days }

            it "should not return application for close of open enrollment" do
              expect(april_sponsor.oe_extended_applications).to be_empty
            end
          end

          context "and monthly open enrollment end date passed for initial application" do
            let(:current_date)  { april_sponsor.open_enrollment_period_for(april_effective_date).max + 2.days }

            it "should return initial application for close of open enrollment" do
              expect(april_sponsor.oe_extended_applications.present?).to eq true
            end
          end
        end
      end
    end

    describe ".application_event_subscriber(aasm)", :dbclean => :after_each do
      let(:aasm_state) { :active }
      let(:sponsorship_state)               { :active }
      let(:effective_date)            { TimeKeeper.date_of_record.next_month.beginning_of_month.last_year  }
      let!(:benefit_sponsorship) do
        create(
          :benefit_sponsors_benefit_sponsorship,
          :with_organization_cca_profile,
          :with_initial_benefit_application,
          default_effective_period: (effective_date..(effective_date + 1.year - 1.day)),
          site: site,
          aasm_state: sponsorship_state,
          initial_application_state: aasm_state
        )
      end
      let!(:application) { benefit_sponsorship.benefit_applications.detect{|app| app.start_on == effective_date} }
      let!(:aasm_state) do
        double(
          "AASM::InstanceBase",
          current_event: :expire!,
          from_state: :active,
          name: :default,
          to_state: :expired
        )
      end

      context "when benefit application is expired" do

        it "should not update benefit sponsorship when benefit application is expired" do
          benefit_sponsorship.application_event_subscriber(application, aasm_state)
          expect(benefit_sponsorship.aasm_state).to eq :active
        end
      end

    end

    describe ".application_event_subscriber(aasm)", :dbclean => :after_each do
      let(:aasm_state) { :active }
      let(:sponsorship_state)               { :active }
      let(:effective_date)            { TimeKeeper.date_of_record.next_month.beginning_of_month.last_year  }
      let!(:benefit_sponsorship) do
        create(
          :benefit_sponsors_benefit_sponsorship,
          :with_organization_cca_profile,
          :with_initial_benefit_application,
          default_effective_period: (effective_date..(effective_date + 1.year - 1.day)),
          site: site,
          aasm_state: sponsorship_state,
          initial_application_state: aasm_state
        )
      end
      let!(:application) { benefit_sponsorship.benefit_applications.detect{|app| app.start_on == effective_date} }


      context "when benefit application is terminated" do

        let!(:aasm_state) do
          double(
            "AASM::InstanceBase",
            current_event: :terminate_enrollment!,
            from_state: :active,
            name: :default,
            to_state: :terminated
          )
        end

        it "should update benefit sponsorship to terminated when benefit application is terminated" do
          benefit_sponsorship.application_event_subscriber(application, aasm_state)
          expect(benefit_sponsorship.aasm_state).to eq :terminated
        end
      end


      context "when benefit application is canceled" do

        let!(:aasm_state) do
          double(
            "AASM::InstanceBase",
            current_event: :activate_enrollment!,
            from_state: :active,
            name: :default,
            to_state: :canceled
          )
        end

        it "should update benefit sponsorship to applicant when benefit application is canceled" do
          benefit_sponsorship.application_event_subscriber(application, aasm_state)
          expect(benefit_sponsorship.aasm_state).to eq :applicant
        end
      end
    end

    describe '.extend_open_enrollment', :dbclean => :after_each do
      let(:aasm_state)                { :canceled }
      let(:sponsorship_state)         { :ineligible }
      let(:effective_date)            { TimeKeeper.date_of_record.next_month.beginning_of_month  }
      let!(:benefit_sponsorship) do
        create(
          :benefit_sponsors_benefit_sponsorship,
          :with_organization_cca_profile,
          :with_initial_benefit_application,
          default_effective_period: (effective_date..(effective_date + 1.year - 1.day)),
          site: site,
          aasm_state: sponsorship_state,
          initial_application_state: aasm_state
        )
      end
      let!(:application)              { benefit_sponsorship.benefit_applications.detect{|app| app.start_on == effective_date} }

      let!(:aasm) do
        double(
          "AASM::InstanceBase",
          current_event: :extend_open_enrollment!,
          from_state: :canceled,
          name: :default,
          to_state: :enrollment_extended
        )
      end

      it 'should move benefit_sponsorship to appropriate state' do
        expect(benefit_sponsorship.aasm_state).to eq :ineligible
        benefit_sponsorship.application_event_subscriber(application, aasm)
        expect(benefit_sponsorship.aasm_state).to eq :applicant
      end
    end

    describe '.late_renewal_benefit_application', :dbclean => :after_each do

      let(:effective_date)            { TimeKeeper.date_of_record.next_month.beginning_of_month  }
      let!(:benefit_sponsorship) do
        create(
            :benefit_sponsors_benefit_sponsorship,
            :with_organization_cca_profile,
            :with_renewal_benefit_application,
            initial_application_state: :active,
            renewal_application_state: :enrollment_ineligible,
            default_effective_period: (effective_date..(effective_date + 1.year - 1.day)),
            site: site,
            aasm_state: :active
        )
      end
      let!(:expired_benefit_application) do
        expired_application = FactoryBot.create(:benefit_sponsors_benefit_application,
                          benefit_sponsorship: benefit_sponsorship,
                          recorded_service_areas: benefit_sponsorship.primary_office_service_areas,
                          aasm_state: :expired,
                          effective_period: (benefit_sponsorship.active_benefit_application.start_on - 1.year..benefit_sponsorship.active_benefit_application.start_on - 1.day))
        active_application = benefit_sponsorship.active_benefit_application
        active_application.predecessor = expired_application
        active_application.save
        expired_application
      end

      before do
        benefit_sponsorship.benefit_applications.each do |ba|
          ba.update_attributes(updated_at: ba.start_on)
        end
      end

      context "when renewal application is ineligible" do
        it 'should return nil' do
          expect(benefit_sponsorship.late_renewal_benefit_application).to eq nil
        end
      end

      context "when renewal application is eligible" do
        before do
          benefit_sponsorship.renewal_benefit_application.update_attributes(aasm_state:'enrollment_eligible')
        end
        it 'should return renewal application' do
          expect(benefit_sponsorship.late_renewal_benefit_application).to eq benefit_sponsorship.renewal_benefit_application
        end
      end
    end

    describe '.is_potential_off_cycle_employer', dbclean: :after_each do

      let!(:rating_area)                   { FactoryBot.create :benefit_markets_locations_rating_area }
      let!(:service_area)                  { FactoryBot.create :benefit_markets_locations_service_area }
      let!(:site)                          { FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let!(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let!(:employer_profile)              { organization.employer_profile }
      let!(:active_benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
      let!(:effective_period)              { (TimeKeeper.date_of_record.beginning_of_month)..(TimeKeeper.date_of_record.beginning_of_month.next_year.prev_day) }
      let!(:renewal_effective_period)      { (TimeKeeper.date_of_record.beginning_of_month.next_year)..(TimeKeeper.date_of_record.beginning_of_month.prev_day + 2.years) }

      shared_examples_for "for an employer on the exchange" do |aasm_state_initial, aasm_state_renewal, expectation|
        let!(:current_application)           { FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: aasm_state_initial, effective_period: effective_period, benefit_sponsorship: active_benefit_sponsorship) }
        let!(:renewal_application) do
          return unless aasm_state_renewal.present?

          FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: aasm_state_renewal, effective_period: renewal_effective_period, benefit_sponsorship: active_benefit_sponsorship)
        end
        it "when #{aasm_state_initial} #{aasm_state_renewal} application(s) are present" do
          expect(active_benefit_sponsorship.is_potential_off_cycle_employer?).to eq expectation
        end
      end

      it_behaves_like "for an employer on the exchange", "enrollment_closed", nil, false
      it_behaves_like "for an employer on the exchange", "enrollment_open", nil, false
      it_behaves_like "for an employer on the exchange", "canceled", nil, false
      it_behaves_like "for an employer on the exchange", "draft", nil, false
      it_behaves_like "for an employer on the exchange", "active", nil, false
      it_behaves_like "for an employer on the exchange", "enrollment_ineligible", nil, true
      it_behaves_like "for an employer on the exchange", "terminated", nil, true
      it_behaves_like "for an employer on the exchange", "termination_pending", nil, true
      it_behaves_like "for an employer on the exchange", "pending", nil, false
      it_behaves_like "for an employer on the exchange", "active", "enrollment_closed", false
      it_behaves_like "for an employer on the exchange", "active", "enrollment_open", false
      it_behaves_like "for an employer on the exchange", "active", "canceled", false
      it_behaves_like "for an employer on the exchange", "active", "draft", false
      it_behaves_like "for an employer on the exchange", "active", "enrollment_ineligible", true
      it_behaves_like "for an employer on the exchange", "active", "terminated", true
      it_behaves_like "for an employer on the exchange", "active", "termination_pending", true
      it_behaves_like "for an employer on the exchange", "active", "pending", false
      it_behaves_like "for an employer on the exchange", "termination_pending", "canceled", true
      it_behaves_like "for an employer on the exchange", "termination_pending", "draft", true
      it_behaves_like "for an employer on the exchange", "termination_pending", "enrollment_open", false
      it_behaves_like "for an employer on the exchange", "termination_pending", "enrollment_closed", false
      it_behaves_like "for an employer on the exchange", "terminated", "canceled", true
      it_behaves_like "for an employer on the exchange", "terminated", "draft", true
      it_behaves_like "for an employer on the exchange", "terminated", "enrollment_open", false
      it_behaves_like "for an employer on the exchange", "terminated", "enrollment_closed", false
      it_behaves_like "for an employer on the exchange", "terminated", "active", false

      context 'employer has multiple canceled applications after terminated application' do
        let(:start_on)                    { TimeKeeper.date_of_record.beginning_of_month.prev_month }
        let(:termination_date)            { TimeKeeper.date_of_record.next_month.end_of_month }
        let!(:renewal_effective_period)   { termination_date.next_day..termination_date.next_day.next_year.prev_day }
        let!(:effective_period)           { start_on..termination_date }
        let!(:term_application)           { FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: :termination_pending, effective_period: effective_period, benefit_sponsorship: active_benefit_sponsorship) }
        let!(:canceled_app1)              { FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: :canceled, effective_period: renewal_effective_period, benefit_sponsorship: active_benefit_sponsorship) }
        let!(:canceled_app2)              { FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: :canceled, effective_period: renewal_effective_period, benefit_sponsorship: active_benefit_sponsorship) }
        let!(:canceled_app3)              { FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: :canceled, effective_period: renewal_effective_period, benefit_sponsorship: active_benefit_sponsorship) }
        let!(:canceled_app4)              { FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: :canceled, effective_period: renewal_effective_period, benefit_sponsorship: active_benefit_sponsorship) }
        let!(:draft_app)                  { FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: :draft, effective_period: renewal_effective_period, benefit_sponsorship: active_benefit_sponsorship) }


        it { expect(active_benefit_sponsorship.is_potential_off_cycle_employer?).to eq true }
      end
    end

    describe '.off_cycle_benefit_application' do
      let!(:rating_area)                   { FactoryBot.create :benefit_markets_locations_rating_area }
      let!(:service_area)                  { FactoryBot.create :benefit_markets_locations_service_area }
      let!(:site)                          { FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let!(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let!(:employer_profile)              { organization.employer_profile }
      let!(:active_benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
      let(:current_date1)                  { TimeKeeper.date_of_record.beginning_of_month.prev_month }
      let!(:effective_period)              { (current_date1)..(current_date1.next_year.prev_day) }
      let!(:renewal_effective_period)      { (current_date1.next_year)..(current_date1.prev_day + 2.years) }

      shared_examples_for "for off-cycle employer" do |aasm_state_initial, aasm_state_renewal, aasm_state_off_cycle, expectation|

        let(:termination_date)               { aasm_state_renewal.present? ? renewal_effective_period.min + 65.days : effective_period.min + 65.days }
        let(:offcycle_effective_period) do
          date = termination_date.end_of_month.next_day
          date..date.next_year.prev_day
        end

        let!(:initial_application) do
          application = FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: aasm_state_initial, effective_period: effective_period, benefit_sponsorship: active_benefit_sponsorship)
          terminated_period = aasm_state_renewal.nil? && ['terminated', 'termination_pending'].include?(aasm_state_initial) ? effective_period.min..termination_date : effective_period
          application.update_attributes!(effective_period: terminated_period)
        end
        let!(:offcycle_application) do
          return unless aasm_state_off_cycle.present?

          FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: aasm_state_off_cycle, effective_period: offcycle_effective_period, benefit_sponsorship: active_benefit_sponsorship)
        end
        let!(:renewal_application) do
          return unless aasm_state_renewal.present?

          terminated_period = ['terminated', 'termination_pending'].include?(aasm_state_renewal) ? renewal_effective_period.min..termination_date : renewal_effective_period
          application = FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: aasm_state_renewal, effective_period: terminated_period, benefit_sponsorship: active_benefit_sponsorship)
          application.update_attributes!(effective_period: terminated_period)
        end
        it "when #{aasm_state_initial} #{aasm_state_renewal} application(s) are present" do
          expect(active_benefit_sponsorship.off_cycle_benefit_application == offcycle_application).to eq expectation if aasm_state_off_cycle.present?
        end

        it { expect(active_benefit_sponsorship.is_off_cycle?).to eq expectation }
      end

      it_behaves_like "for off-cycle employer", "enrollment_closed", nil, nil, false
      it_behaves_like "for off-cycle employer", "enrollment_open", nil, nil, false
      it_behaves_like "for off-cycle employer", "active", nil, nil, false
      it_behaves_like "for off-cycle employer", "draft", nil, nil, false
      it_behaves_like "for off-cycle employer", "canceled", nil, "draft", false
      it_behaves_like "for off-cycle employer", "enrollment_ineligible", nil, "draft", true
      it_behaves_like "for off-cycle employer", "enrollment_ineligible", nil, "enrollment_open", true
      it_behaves_like "for off-cycle employer", "enrollment_ineligible", nil, "active", true
      it_behaves_like "for off-cycle employer", "terminated", nil, "draft", true
      it_behaves_like "for off-cycle employer", "terminated", nil, "enrollment_open", true
      it_behaves_like "for off-cycle employer", "terminated", nil, "active", true
      it_behaves_like "for off-cycle employer", "termination_pending", nil, "draft", true
      it_behaves_like "for off-cycle employer", "termination_pending", nil, "enrollment_open", true
      it_behaves_like "for off-cycle employer", "termination_pending", nil, "active", true
      it_behaves_like "for off-cycle employer", "active", nil, "", false
      it_behaves_like "for off-cycle employer", "active", "enrollment_ineligible", "draft", true
      it_behaves_like "for off-cycle employer", "active", "enrollment_open", nil, false
      it_behaves_like "for off-cycle employer", "active", "enrollment_close", nil, false
      it_behaves_like "for off-cycle employer", "active", "draft", nil, false
      it_behaves_like "for off-cycle employer", "active", "enrollment_ineligible", nil, false
      it_behaves_like "for off-cycle employer", "active", "terminated", "draft", true
      it_behaves_like "for off-cycle employer", "active", "termination_pending", "draft", true

      context "benefit application with reinstated id " do
        let!(:application) { FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: :active, benefit_sponsorship: active_benefit_sponsorship) }
        let!(:term_application) { FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: :terminated, benefit_sponsorship: active_benefit_sponsorship) }

        before do
          term_application.update_attributes(effective_period: Date.new(TimeKeeper.date_of_record.year, 1, 1)..Date.new(TimeKeeper.date_of_record.year, 1, 31))
          application.update_attributes(effective_period: Date.new(TimeKeeper.date_of_record.year, 2, 1)..Date.new(TimeKeeper.date_of_record.year, 12, 31), reinstated_id: term_application.id)
        end

        it "should return nil" do
          expect(active_benefit_sponsorship.off_cycle_benefit_application).to eq nil
        end
      end

      context "benefit application with predecessor_id " do
        let!(:application) { FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: :active, benefit_sponsorship: active_benefit_sponsorship) }
        let!(:expired_application) { FactoryBot.create(:benefit_sponsors_benefit_application, aasm_state: :expired, benefit_sponsorship: active_benefit_sponsorship) }

        before do
          expired_application.update_attributes(effective_period: Date.new(TimeKeeper.date_of_record.last_year.year, 1, 1)..Date.new(TimeKeeper.date_of_record.last_year.year, 12, 31))
          application.update_attributes(effective_period: Date.new(TimeKeeper.date_of_record.year, 1, 1)..Date.new(TimeKeeper.date_of_record.year, 12, 31), predecessor_id: expired_application.id)
        end

        it "should return nil" do
          expect(active_benefit_sponsorship.off_cycle_benefit_application).to eq nil
        end
      end
    end

    describe '.future_active_reinstated_benefit_application', :dbclean => :after_each do

      let(:benefit_sponsorship)                 { employer_profile.add_benefit_sponsorship }
      let(:this_year)                           { Date.today.year }
      let(:benefit_sponsor_catalog) { FactoryBot.create(:benefit_markets_benefit_sponsor_catalog, service_areas: [service_area]) }
      let(:service_area) { create_default(:benefit_markets_locations_service_area) }
      let(:benefit_application) do
        build(
          :benefit_sponsors_benefit_application,
          benefit_sponsorship: benefit_sponsorship,
          recorded_service_areas: benefit_sponsorship.service_areas,
          benefit_sponsor_catalog: benefit_sponsor_catalog
        )
      end

      it 'should return future_active_reinstated_benefit_application' do
        period = benefit_application.effective_period.min + 1.year..(benefit_application.effective_period.max + 1.year)
        benefit_application.update_attributes!(reinstated_id: BSON::ObjectId.new, aasm_state: :active, effective_period: period)
        expect(benefit_sponsorship.future_active_reinstated_benefit_application).to eq benefit_application
      end

      it 'should return nil if no reinstated enrollment present' do
        expect(benefit_sponsorship.future_active_reinstated_benefit_application).to eq nil
      end
    end
  end
end
