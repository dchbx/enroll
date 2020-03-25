require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require File.join(File.dirname(__FILE__), "..", "..", "..", "support/benefit_sponsors_product_spec_helpers")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::BenefitApplicationService, type: :model, :dbclean => :after_each do
    subject { ::BenefitSponsors::Services::BenefitApplicationService.new }

    def init_form_for_create
      ::BenefitSponsors::Forms::BenefitApplicationForm.for_create(create_ba_params)
    end

    def set_bs_for_service(ba_form)
      subject.find_benefit_sponsorship(ba_form)
    end

    describe "constructor" do
      let(:benefit_sponser_ship) { double("BenefitSponsorship", {
          :benefit_market => "BenefitMarket",
          :profile_id => "rspec-id",
          :organization => "Organization"
      })}
      let(:benefit_factory) { double("BenefitApplicationFactory", benefit_sponser_ship: benefit_sponser_ship) }

      it "should initialize service factory" do
        service_obj = Services::BenefitApplicationService.new(benefit_factory)
        expect(service_obj.benefit_application_factory).to eq benefit_factory
      end
    end

    describe ".store service" do
      include_context "setup benefit market with market catalogs and product packages"

      let(:current_effective_date) { effective_period_start_on }
      let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
      let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
      let(:effective_period)          { effective_period_start_on..effective_period_end_on }

      let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
      let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }
      let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

      let(:params) do
        {
            effective_period: effective_period,
            open_enrollment_period: open_enrollment_period,
        }
      end

      let(:benefit_application_form) { FactoryBot.build(:benefit_sponsors_forms_benefit_application) }
      let!(:invalid_application_form) { BenefitSponsors::Forms::BenefitApplicationForm.new}
      let!(:invalid_benefit_application) { BenefitSponsors::BenefitApplications::BenefitApplication.new }

      let!(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:benefit_sponsorship) do
        FactoryBot.create(
          :benefit_sponsors_benefit_sponsorship,
          :with_rating_area,
          :with_service_areas,
          supplied_rating_area: rating_area,
          service_area_list: [service_area],
          organization: organization,
          profile_id: organization.profiles.first.id,
          benefit_market: site.benefit_markets[0],
          employer_attestation: employer_attestation)
      end

      let(:benefit_application)       { benefit_sponsorship.benefit_applications.new(params) }
      let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
      let!(:benefit_application_factory) { BenefitSponsors::BenefitApplications::BenefitApplicationFactory }

      before do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      context "has received valid attributes" do
        it "should save updated benefit application" do
          service_obj = Services::BenefitApplicationService.new(benefit_application_factory)
          expect(service_obj.store(benefit_application_form, benefit_application)).to eq [true, benefit_application]
        end
      end

      context ".save" do
        it "benefit application form has benefit sponsorship with terminated state should revert to applicant state on save" do
          service_obj = Services::BenefitApplicationService.new(benefit_application_factory)
          benefit_sponsorship.update_attributes(aasm_state: :terminated)
          benefit_application_form['benefit_sponsorship_id'] = benefit_sponsorship.id
          service_obj.save(benefit_application_form)
          benefit_sponsorship.reload
          expect(benefit_sponsorship.aasm_state).to eq :applicant

        end
      end

      context "has received invalid attributes" do
        it "should map the errors to benefit application" do
          allow(benefit_application_factory).to receive(:validate).with(invalid_benefit_application).and_return false
          expect(invalid_application_form.valid?).to be_falsy
          expect(invalid_benefit_application.valid?).to be_falsy
          # TODO: add expectations to match the errors instead of counts
          # expect(invalid_application_form.errors.count).to eq 4
          service_obj = Services::BenefitApplicationService.new(benefit_application_factory)
          expect(service_obj.store(invalid_application_form, invalid_benefit_application)).to eq [false, nil]
          # expect(invalid_application_form.errors.count).to eq 8
        end
      end
    end

    describe ".load_form_metadata" do
      let(:benefit_application_form) { BenefitSponsors::Forms::BenefitApplicationForm.new }
      let(:subject) { BenefitSponsors::Services::BenefitApplicationService.new }
      it "should assign attributes of benefit application to form" do
        subject.load_form_metadata(benefit_application_form)
        expect(benefit_application_form.start_on_options).not_to be nil
      end
    end

    describe ".load_form_params_from_resource" do
      let!(:site)  { FactoryBot.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, :with_benefit_market_catalog_and_product_packages, :cca) }
      let!(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let!(:rating_area)   { FactoryBot.create_default :benefit_markets_locations_rating_area }
      let!(:service_area)  { FactoryBot.create_default :benefit_markets_locations_service_area }
      let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
      let!(:benefit_market) { site.benefit_markets.first }

      let(:benefit_sponsorship) do
        FactoryBot.create(
          :benefit_sponsors_benefit_sponsorship,
          :with_rating_area,
          :with_service_areas,
          supplied_rating_area: rating_area,
          service_area_list: [service_area],
          organization: organization,
          profile_id: organization.profiles.first.id,
          benefit_market: benefit_market,
          employer_attestation: employer_attestation)
      end

      let(:benefit_application) { FactoryBot.create(:benefit_sponsors_benefit_application, benefit_sponsorship: benefit_sponsorship) }
      let(:benefit_application_form) { FactoryBot.build(:benefit_sponsors_forms_benefit_application, id: benefit_application.id) }
      let(:subject) { BenefitSponsors::Services::BenefitApplicationService.new }

      it "should assign the form attributes from benefit application" do
        form = subject.load_form_params_from_resource(benefit_application_form)
        expect(form[:start_on]).to eq benefit_application.start_on.to_date.to_s
        expect(form[:end_on]).to eq benefit_application.end_on.to_date.to_s
        expect(form[:open_enrollment_start_on]).to eq benefit_application.open_enrollment_start_on.to_date.to_s
        expect(form[:open_enrollment_end_on]).to eq benefit_application.open_enrollment_end_on.to_date.to_s
        expect(form[:pte_count]).to eq benefit_application.pte_count
        expect(form[:msp_count]).to eq benefit_application.msp_count
      end
    end

    describe '.can_create_draft_ba?' do
      let!(:rating_area)                  { FactoryBot.create_default :benefit_markets_locations_rating_area }
      let!(:service_area)                 { FactoryBot.create_default :benefit_markets_locations_service_area }
      let(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:employer_profile)              { organization.employer_profile }
      let(:start_on)                      { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
      let(:end_on)                        { start_on + 1.year - 1.day }
      let(:benefit_sponsorship) do
        bs = employer_profile.add_benefit_sponsorship
        bs.save!
        bs
      end

      let(:create_ba_params) do
        {
          "start_on" => start_on.strftime('%m/%d/%Y'), "end_on" => end_on, "fte_count" => "11",
          "open_enrollment_start_on" => "01/15/2019", "open_enrollment_end_on" => "01/20/2019",
          "benefit_sponsorship_id" => benefit_sponsorship.id.to_s
        }
      end

      before do
        @form = init_form_for_create
      end

      #for existing active states in as per active_states_per_dt_action
      [:active, :pending, :enrollment_open, :binder_paid, :enrollment_closed, :enrollment_ineligible, :termination_pending].each do |active_state|
        context 'with dt active state' do
          let!(:ba) { FactoryBot.create(:benefit_sponsors_benefit_application, benefit_sponsorship: benefit_sponsorship, aasm_state: active_state) }

          it 'should return false as dt active state exists for one of the bas' do
            set_bs_for_service(@form)
            expect(subject.can_create_draft_ba?).to be_falsy
          end
        end
      end

      context 'with dt draft state' do
        let!(:ba) { FactoryBot.create(:benefit_sponsors_benefit_application, benefit_sponsorship: benefit_sponsorship, aasm_state: :draft) }

        it 'should return false as dt active state exists for one of the bas' do
          set_bs_for_service(@form)
          expect(subject.can_create_draft_ba?).to be_truthy
        end
      end
    end

    describe '.create_or_cancel_draft_ba' do
      let!(:rating_area)                  { FactoryBot.create_default :benefit_markets_locations_rating_area }
      let!(:service_area)                 { FactoryBot.create_default :benefit_markets_locations_service_area }
      let(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:benefit_market)                { site.benefit_markets.first }
      let(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:employer_profile)              { organization.employer_profile }
      let(:benefit_sponsorship) do
        bs = employer_profile.add_benefit_sponsorship
        bs.save!
        bs
      end
      let(:effective_period)              { Date.new(2019, 02, 01)..Date.new(2020,01,31) }
      let(:create_ba_params) do
        {
          "start_on" => effective_period.min.to_s, "end_on" => effective_period.max.to_s, "fte_count" => "11",
          "open_enrollment_start_on" => "01/15/2019", "open_enrollment_end_on" => "01/20/2019",
          "benefit_sponsorship_id" => benefit_sponsorship.id.to_s
        }
      end
      let!(:current_benefit_market_catalog) do
        BenefitSponsors::ProductSpecHelpers.construct_benefit_market_catalog_with_renewal_catalog(site, benefit_market, effective_period)
        benefit_market.benefit_market_catalogs.where(
          "application_period.min" => effective_period.min.to_s
        ).first
      end

      context 'for admin_datatable_action' do
        let!(:ba)   { FactoryBot.create(:benefit_sponsors_benefit_application, benefit_sponsorship: benefit_sponsorship, aasm_state: :imported) }
        let!(:ba2)  { FactoryBot.create(:benefit_sponsors_benefit_application, benefit_sponsorship: benefit_sponsorship, aasm_state: :draft) }

        before :each do
          create_ba_params.merge!({ pte_count: '0', msp_count: '0', admin_datatable_action: true })
          @form = init_form_for_create
        end

        context 'with ba in draft state' do
          it 'should return true and instance as ba succesfully created' do
            set_bs_for_service(@form)
            @model_attrs = subject.form_params_to_attributes(@form)
            result = subject.create_or_cancel_draft_ba(@form, @model_attrs)
            benefit_sponsorship.reload
            expect(result).to eq [true, benefit_sponsorship.benefit_applications.last]
          end
        end

        [:pending, :enrollment_open, :enrollment_closed, :binder_paid, :enrollment_ineligible, :termination_pending].each do |active_state|
          context 'with dt not in active states' do

            before do
              ba.destroy!
              ba2.update_attribute(:aasm_state, active_state)
              set_bs_for_service(@form)
              @model_attrs = subject.form_params_to_attributes(@form)
              @result = subject.create_or_cancel_draft_ba(@form, @model_attrs)
              benefit_sponsorship.reload
            end

            it 'should add errors to form' do
              expect(@form.errors.full_messages).to eq ['Existing plan year with overlapping coverage exists']
            end

            it 'should return a combination of false and nil' do
              expect(@result).to eq [false, nil]
            end
          end
        end
      end

      context 'not for admin_datatable_action' do
        before :each do
          @form = init_form_for_create
          set_bs_for_service(@form)
          @model_attrs = subject.form_params_to_attributes(@form)
        end

        it 'should return true and instance as ba succesfully created' do
          result = subject.create_or_cancel_draft_ba(@form, @model_attrs)
          benefit_sponsorship.reload
          expect(result).to eq [true, benefit_sponsorship.benefit_applications.first]
        end
      end
    end

    describe '.has_an_active_ba?' do
      let!(:rating_area)                  { FactoryBot.create_default :benefit_markets_locations_rating_area }
      let!(:service_area)                 { FactoryBot.create_default :benefit_markets_locations_service_area }
      let(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:employer_profile)              { organization.employer_profile }
      let(:benefit_sponsorship) do
        bs = employer_profile.add_benefit_sponsorship
        bs.save!
        bs
      end

      let(:create_ba_params) do
        {
          "start_on" => "02/01/2019",
          "end_on" => "01/31/2020",
          "fte_count" => "11",
          "open_enrollment_start_on" => "01/15/2019",
          "open_enrollment_end_on" => "01/20/2019",
          "benefit_sponsorship_id" => benefit_sponsorship.id.to_s
        }
      end

      [:active, :pending, :enrollment_open, :binder_paid, :enrollment_closed, :enrollment_ineligible, :termination_pending].each do |active_state|
        context 'for benefit applications in active states' do
          let!(:ba) { FactoryBot.create(:benefit_sponsors_benefit_application, benefit_sponsorship: benefit_sponsorship, aasm_state: active_state) }

          it 'should return true as no bas has dt active state' do
            set_bs_for_service(init_form_for_create)
            expect(subject.has_an_active_ba?).to be_truthy
          end
        end
      end

      [:terminated, :canceled, :suspended].each do |non_active_state|
        context 'for benefit applications in non active states' do
          let!(:ba) { FactoryBot.create(:benefit_sponsors_benefit_application, benefit_sponsorship: benefit_sponsorship, aasm_state: non_active_state) }
          it 'should return false as no bas has dt active state' do
            set_bs_for_service(init_form_for_create)
            expect(subject.has_an_active_ba?).to be_falsy
          end
        end
      end
    end

    # describe ".publish" do
    #   let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsors_benefit_sponsorship, :with_full_package)}
    #   let(:benefit_application) { FactoryBot.create(:benefit_sponsors_benefit_application, benefit_sponsorship: benefit_sponsorship) }
    #   let(:benefit_application_form) { FactoryBot.build(:benefit_sponsors_forms_benefit_application, id: benefit_application.id ) }
    #   let(:subject) { BenefitSponsors::Services::BenefitApplicationService.new }
    #
    #   context "has to publish and " do
    #     it "Should validate " do
    #       allow(benefit_sponsorship.profile).to receive(:is_primary_office_local?).and_return true
    #       subject.publish(benefit_application_form)
    #
    #
    #     end
    #   end
    # end
  end
end
