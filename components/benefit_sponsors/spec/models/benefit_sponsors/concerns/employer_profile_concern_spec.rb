require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module BenefitSponsors
  RSpec.describe Concerns::EmployerProfileConcern, type: :model, dbclean: :after_each do
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
      let(:ga_legal_name) {plan_design_organization_with_assigned_ga.general_agency_profile.legal_name.to_s}
      let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:abc_profile)    { organization.employer_profile }

      it 'should return legal name when GA account is assigned' do
        expect(employer_profile.active_ga_legal_name).to eq ga_legal_name
      end

      it 'should return nil when GA account is not assigned' do
        expect(abc_profile.active_ga_legal_name).to be nil
      end
    end
  end
end
