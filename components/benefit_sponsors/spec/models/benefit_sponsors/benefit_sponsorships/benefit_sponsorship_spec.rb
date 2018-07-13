require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitSponsorships::BenefitSponsorship, type: :model, dbclean: :after_each do
    let!(:previous_rating_area) { create_default(:benefit_markets_locations_rating_area, active_year: Date.current.year - 1) }
    let!(:previous_service_area) { create_default(:benefit_markets_locations_service_area, active_year: Date.current.year - 1) }
    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
    let!(:service_area) { create_default(:benefit_markets_locations_service_area) }

    let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:benefit_market)  { site.benefit_markets.first }

    let(:employer_organization)   { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
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
          let(:invalid_organization)  { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }

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
      let(:linked_organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
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
        let(:valid_build_benefit_sponsorship)  { FactoryGirl.build(:benefit_sponsors_benefit_sponsorship, :with_full_package) }
        let(:valid_create_benefit_sponsorship) { FactoryGirl.create(:benefit_sponsors_benefit_sponsorship, :with_market_profile)}

        it "with_full_package build should be valid" do
          expect(valid_build_benefit_sponsorship.valid?).to be_truthy
        end

        it "with_market_profile create should be valid" do
          expect(valid_create_benefit_sponsorship.valid?).to be_truthy
        end
      end

      context "when benefit sponsorship is CCA SHOP employer" do
        let(:cca_employer_organization)   { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
        let(:cca_profile)                 { cca_employer_organization.employer_profile  }
        let(:benefit_sponsorship)         { cca_profile.add_benefit_sponsorship }

        it "should be valid" do
          expect(benefit_sponsorship.valid?).to be true
        end
      end
    end

    describe "Finding a BenefitSponsorCatalog" do
      let(:benefit_sponsorship)                 { employer_profile.add_benefit_sponsorship }
      let(:next_year)                           { Date.today.year + 1 }
      let(:application_period_next_year)        { (Date.new(next_year,1,1))..(Date.new(next_year,12,31)) }
      let!(:benefit_market_catalog_next_year)   { FactoryGirl.build(:benefit_markets_benefit_market_catalog, benefit_market: nil, application_period: application_period_next_year) }

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
          expect(benefit_sponsorship.benefit_sponsor_catalog_for([], effective_date)).to be_an_instance_of(BenefitMarkets::BenefitSponsorCatalog)
        end
      end

      context "given an effective_date in future, undefined application period" do
        let(:future_effective_date)  { Date.new((next_year + 2),1,1) }

        it "should not find a benefit_market_catalog" do
          expect{benefit_sponsorship.benefit_sponsor_catalog_for([], future_effective_date)}.to raise_error(/benefit_market_catalog not found for effective date: #{future_effective_date}/)
        end
      end
    end

    describe "Working with subclassed parent Profiles" do
      context "using sic_code helper method" do
        let(:cca_employer_organization)   { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
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
      let(:benefit_application)                 { build(:benefit_sponsors_benefit_application,
                                                        benefit_sponsorship: benefit_sponsorship,
                                                        recorded_service_areas: benefit_sponsorship.service_areas) }

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

            it "benefit_sponsorship should transition to state: :initial_application_approved" do
              expect(benefit_sponsorship.aasm_state).to eq :initial_application_approved
            end

            context "and open enrollment period begins" do
              before {
                TimeKeeper.set_date_of_record_unprotected!(benefit_application.open_enrollment_period.min)
                benefit_application.begin_open_enrollment!
              }

              after {
                TimeKeeper.set_date_of_record_unprotected!(Date.today)
              }

              it "should transition to state: :initial_enrollment_open" do
                expect(benefit_sponsorship.aasm_state).to eq :initial_enrollment_open
              end

              context "and open enrollment period ends" do
                before {
                  TimeKeeper.set_date_of_record_unprotected!(benefit_application.open_enrollment_period.max)
                  benefit_application.end_open_enrollment!
                }

                after {
                  TimeKeeper.set_date_of_record_unprotected!(Date.today)
                }

                it "benefit_sponsorship should transition to state: :initial_enrollment_closed" do
                  expect(benefit_sponsorship.aasm_state).to eq :initial_enrollment_closed
                end

                context "and binder payment is credited" do
                  before { benefit_sponsorship.credit_binder! }

                  it "benefit_sponsorship should transition to state: :initial_enrollment_eligible" do
                    expect(benefit_sponsorship.aasm_state).to eq :initial_enrollment_eligible
                  end

                  it "benefit_application should transition to state: :enrollment_eligible" do
                    expect(benefit_application.aasm_state).to eq :enrollment_eligible
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

                  context "and binder payment is reversed" do
                    before { benefit_sponsorship.reverse_binder! }

                    it "benefit_sponsorship should transition to state: :initial_enrollment_closed" do
                      expect(benefit_sponsorship.aasm_state).to eq :binder_reversed
                    end

                    it "benefit_application should transition to state: enrollment_closed" do
                      expect(benefit_application.aasm_state).to eq :enrollment_closed
                    end

                    context "and effective period begins" do
                      before {
                        TimeKeeper.set_date_of_record_unprotected!(benefit_application.effective_period.min)
                        benefit_application.activate_enrollment!
                      }
                      after {
                        TimeKeeper.set_date_of_record_unprotected!(Date.today)
                      }

                      it "benefit_sponsorship should transition to state: :applicant" do
                        expect(benefit_sponsorship.aasm_state).to eq :applicant
                      end

                      it "benefit_application should transition to state: :canceled" do
                        expect(benefit_application.aasm_state).to eq :canceled
                      end
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

            it "benefit_sponsorship should transition to state: :initial_application_under_review" do
              expect(benefit_sponsorship.aasm_state).to eq :initial_application_under_review
            end

            context "and it's denied by HBX" do
              before { benefit_application.deny_application! }

              it "benefit_application should transition to state: :denied" do
                expect(benefit_application.aasm_state).to eq :denied
              end

              it "benefit_sponsorship should transition to state: :initial_application_denied" do
                expect(benefit_sponsorship.aasm_state).to eq :initial_application_denied
              end
            end

            context "and it's approved by HBX" do
              before { benefit_application.approve_application! }

              it "benefit_application should transition to state: :approved" do
                expect(benefit_application.aasm_state).to eq :approved
              end

              it "benefit_sponsorship should transition to state: :initial_application_approved" do
                expect(benefit_sponsorship.aasm_state).to eq :initial_application_approved
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

    describe "Scopes", :dbclean => :after_each do
      let!(:rating_area)                    { FactoryGirl.create(:benefit_markets_locations_rating_area)  }
      let!(:service_area)                    { FactoryGirl.create(:benefit_markets_locations_service_area)  }
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


      let!(:march_sponsors)                 { create_list(:benefit_sponsors_benefit_sponsorship, 3, :with_organization_cca_profile,
                                                          :with_initial_benefit_application, initial_application_state: initial_application_state,
                                                          default_effective_period: (march_effective_date..(march_effective_date + 1.year - 1.day)), site: site, aasm_state: sponsorship_state)
                                              }

      let!(:april_sponsors)                 { create_list(:benefit_sponsors_benefit_sponsorship, 2, :with_organization_cca_profile,
                                                          :with_initial_benefit_application, initial_application_state: initial_application_state,
                                                          default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site, aasm_state: sponsorship_state)
                                              }

      let!(:april_renewal_sponsors)         { create_list(:benefit_sponsors_benefit_sponsorship, 2, :with_organization_cca_profile,
                                                          :with_renewal_benefit_application, initial_application_state: renewal_current_application_state,
                                                          renewal_application_state: renewal_application_state,
                                                          default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site,
                                                          aasm_state: :active)
                                              }

      before { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

      subject { BenefitSponsors::BenefitSponsorships::BenefitSponsorship }

      context '.may_begin_open_enrollment?' do
        let(:initial_application_state) { :approved }

        it "should find sponsorships with application in approved state and matching open enrollment begin date" do
          expect(subject.may_begin_open_enrollment?(april_open_enrollment_begin_on).size).to eq (march_sponsors.size + april_sponsors.size)
          expect(subject.may_begin_open_enrollment?(april_open_enrollment_begin_on).to_a).to eq (march_sponsors + april_sponsors)
        end
      end

      context '.may_end_open_enrollment?' do
        let(:initial_application_state) { :enrollment_open }
        let(:renewal_application_state) { :enrollment_open }

        it "should find sponsorships with application in enrollment_open state and matching open enrollment end date" do
          expect(subject.may_end_open_enrollment?(april_open_enrollment_end_on.next_day).size).to eq (march_sponsors.size + april_sponsors.size + april_renewal_sponsors.size)
          expect(subject.may_end_open_enrollment?(april_open_enrollment_end_on.next_day).to_a).to eq (march_sponsors + april_sponsors + april_renewal_sponsors)
        end
      end

      context '.may_begin_benefit_coverage?' do
        let(:initial_application_state) { :enrollment_eligible }
        let(:renewal_application_state) { :enrollment_eligible }

        it "should find sponsorships with application in enrollment_eligible state and matching effective period begin date" do
          expect(subject.may_begin_benefit_coverage?(march_effective_date).size).to eq (march_sponsors.size)
          expect(subject.may_begin_benefit_coverage?(march_effective_date).to_a).to eq (march_sponsors)

          expect(subject.may_begin_benefit_coverage?(april_effective_date).size).to eq (march_sponsors.size + april_sponsors.size + april_renewal_sponsors.size)
          expect(subject.may_begin_benefit_coverage?(april_effective_date).to_a).to eq (march_sponsors + april_sponsors + april_renewal_sponsors)
        end
      end

      context '.may_end_benefit_coverage?' do
        let(:initial_application_state) { :active }
        let(:renewal_application_state) { :active }
        let(:renewal_current_application_state) { :expired }

        it "should find sponsorships with application in active state and matching effective period end date" do
          expect(subject.may_end_benefit_coverage?(march_effective_date.next_year).size).to eq (march_sponsors.size)
          expect(subject.may_end_benefit_coverage?(march_effective_date.next_year).to_a).to eq (march_sponsors)

          expect(subject.may_end_benefit_coverage?(april_effective_date.next_year).size).to eq (march_sponsors.size + april_sponsors.size + april_renewal_sponsors.size)
          expect(subject.may_end_benefit_coverage?(april_effective_date.next_year).to_a).to eq (march_sponsors + april_sponsors + april_renewal_sponsors)
        end
      end

      context '.may_renew_application?' do
        let(:initial_application_state) { :active }

        it "should find sponsorships with application in active state and matching effective period begin date" do
          expect(subject.may_renew_application?(april_effective_date.prev_day).size).to eq (april_renewal_sponsors.size)
          expect(subject.may_renew_application?(april_effective_date.prev_day).to_a).to eq (april_renewal_sponsors)
        end
      end

      context '.may_terminate_benefit_coverage?' do

        it "should find sponsorships with application in termination_pending state and matching terminated_on date" do
        end
      end

      context '.may_transmit_initial_enrollment?' do
        let(:initial_application_state) { :enrollment_eligible }
        let(:sponsorship_state) { :initial_enrollment_eligible }

        let!(:april_ineligible_initial_sponsors)  { create_list(:benefit_sponsors_benefit_sponsorship, 2, :with_organization_cca_profile,
                                                                :with_initial_benefit_application, initial_application_state: :enrollment_ineligible,
                                                                default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site, aasm_state: sponsorship_state)
                                              
        }

        let!(:april_wrong_sponsorship_initial_sponsors)  { create_list(:benefit_sponsors_benefit_sponsorship, 2, :with_organization_cca_profile,
                                                                :with_initial_benefit_application, initial_application_state: :enrollment_ineligible,
                                                                default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site, aasm_state: :initial_enrollment_ineligible)
                                              
        }

        it "should fetch only valid initial applications" do 
          applications = subject.may_transmit_initial_enrollment?(april_effective_date)

          expect(applications & april_sponsors).to eq april_sponsors
          expect(applications & april_ineligible_initial_sponsors).to be_empty
          expect(applications & april_wrong_sponsorship_initial_sponsors).to be_empty
        end

      end

      context '.may_transmit_renewal_enrollment?' do

        let(:renewal_application_state) { :enrollment_eligible }

        let!(:april_ineligible_renewal_sponsors)  { create_list(:benefit_sponsors_benefit_sponsorship, 2, :with_organization_cca_profile,
                                                                :with_renewal_benefit_application, initial_application_state: initial_application_state,
                                                                renewal_application_state: :enrollment_ineligible,
                                                                default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site,
                                                                aasm_state: :active)
        }

        let!(:april_wrong_sponsorship_renewal_sponsors)  { create_list(:benefit_sponsors_benefit_sponsorship, 1, :with_organization_cca_profile,
                                                                :with_renewal_benefit_application, initial_application_state: initial_application_state,
                                                                renewal_application_state: :enrollment_eligible,
                                                                default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site,
                                                                aasm_state: :applicant)
        }

        it "should fetch only valid renewal applications" do 
          applications = subject.may_transmit_renewal_enrollment?(april_effective_date)

          expect(applications & april_renewal_sponsors).to eq april_renewal_sponsors
          expect(applications & april_ineligible_renewal_sponsors).to be_empty
          expect(applications & april_wrong_sponsorship_renewal_sponsors).to be_empty
        end
      end


      context '.may_auto_submit_application?' do
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


  end
end
