require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitSponsorships::AcaShopBenefitSponsorshipService, dbclean: :after_each do

    let!(:previous_rating_area) { create_default(:benefit_markets_locations_rating_area, active_year: Date.current.year - 1) }
    let!(:previous_service_area) { create_default(:benefit_markets_locations_service_area, active_year: Date.current.year - 1) }
    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
    let!(:service_area) { create_default(:benefit_markets_locations_service_area) }

    let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:benefit_market)  { site.benefit_markets.first }

    let(:employer_organization)   { FactoryBot.build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)        { employer_organization.employer_profile }

    let!(:rating_area)                    { FactoryBot.create(:benefit_markets_locations_rating_area)  }
    let!(:service_area)                    { FactoryBot.create(:benefit_markets_locations_service_area)  }
    let(:this_year)                       { TimeKeeper.date_of_record.year }

    let(:april_effective_date)            { Date.new(this_year,4,1) }
    let(:april_open_enrollment_begin_on)  { april_effective_date - 1.month }
    let(:april_open_enrollment_end_on)    { april_open_enrollment_begin_on + 9.days }

    let(:initial_application_state)       { :active }
    let(:renewal_application_state)       { :enrollment_open }

    let(:sponsorship_state)               { :active }
    let(:renewal_sponsorship_state)       { :active }
    let(:renewal_current_application_state) { :active }

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

    let(:april_renewal_sponsors) do
      create_list(
        :benefit_sponsors_benefit_sponsorship,
        2,
        :with_organization_cca_profile,
        :with_previous_year_rating_area,
        :with_previous_year_service_areas,
        :with_renewal_benefit_application,
        initial_application_state: renewal_current_application_state,
        renewal_application_state: renewal_application_state,
        default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)),
        site: site,
        aasm_state: renewal_sponsorship_state
      )
    end

    let(:current_date)                    { Date.new(this_year,3,14) }

    subject { BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService }

    # We are not moving benefit applications to ineligible status automatically if binder payment is missed
    # describe '.mark_initial_ineligible' do
    #   let(:sponsorship_state)               { :applicant }
    #   let(:initial_application_state)       { :enrollment_closed }

    #   context  'when initial employer missed binder payment' do

    #     it "should move applications into ineligible state" do
    #       april_sponsors.each do |sponsor|

    #         sponsorship_service = subject.new(benefit_sponsorship: sponsor)
    #         sponsorship_service.mark_initial_ineligible

    #         sponsor.reload

    #         expect(sponsor.applicant?).to be_truthy
    #         expect(sponsor.benefit_applications.first.enrollment_ineligible?).to be_truthy
    #       end
    #     end
    #   end
    # end

    describe '.auto_cancel_enrollment_closed', dbclean: :after_each do
      let(:sponsorship_state)               { :applicant }
      let(:initial_application_state)       { :enrollment_closed }
      let(:renewal_application_state)       { :enrollment_ineligible }
      let(:application_effective_date)      { april_sponsors.first.benefit_applications.first.effective_period.min }

      before do
        TimeKeeper.set_date_of_record_unprotected!(application_effective_date)
      end

      after do
        # Does this do what we think it does?
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      context 'cancel the application when under enrollment close state' do

        it "should move closed applications into canceled state" do
          benefit_application = april_sponsors.first.benefit_applications.first if benefit_application.blank?

          expect(april_sponsors.first.applicant?).to be_truthy
          expect(benefit_application.enrollment_closed?).to be_truthy
          sponsorship_service = subject.new(benefit_sponsorship: april_sponsors.first)
          sponsorship_service.auto_cancel_ineligible

          april_sponsors.first.reload
          benefit_application.reload

          expect(april_sponsors.first.applicant?).to be_truthy
          expect(benefit_application.canceled?).to be_truthy
        end

        it "should not move ineligible applications into canceled state" do
          benefit_application = april_renewal_sponsors.first.benefit_applications.detect(&:is_renewing?)

          expect(april_renewal_sponsors.first.applicant?).to be_falsey
          expect(benefit_application.enrollment_closed?).to be_falsey
          sponsorship_service = subject.new(benefit_sponsorship: april_renewal_sponsors.first)
          sponsorship_service.auto_cancel_ineligible

          april_renewal_sponsors.first.reload
          benefit_application.reload

          expect(april_renewal_sponsors.first.applicant?).to be_falsey
          expect(benefit_application.canceled?).to be_falsey
        end

      end
    end

    describe '.terminate_pending_sponsor_benefit' do

      let(:initial_application_state)   { :termination_pending }
      let(:ba_start_on) { (current_date.beginning_of_month - 2.months) }

      it 'terminate pending benefit application should be terminated when the end on is reached' do
        april_sponsors.each do |sponsor|
          sponsor.benefit_applications.each do |ba|
            ba.update_attributes!(effective_period: ba_start_on..current_date.prev_day, terminated_on: current_date.prev_month)
          end
          benefit_application = sponsor.benefit_applications.termination_pending.first
          service = subject.new(benefit_sponsorship: sponsor, new_date: benefit_application.effective_period.max.next_day)
          service.terminate_pending_sponsor_benefit
          sponsor.reload
          benefit_application.reload

          expect(benefit_application.aasm_state).to eq :terminated
        end
      end
    end

    describe '.end_open_enrollment' do 
      let(:sponsorship_state)               { :applicant }
      let(:business_policy) { double(success_results: [], fail_results: []) }

      before do
        allow_any_instance_of(::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService).to receive(:business_policy_satisfied_for?).and_return(true)
        allow_any_instance_of(::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService).to receive(:calculate_pricing_determinations).and_return(true)
        allow_any_instance_of(::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService).to receive(:business_policy).and_return(business_policy)
      end

      context  'For initial employers for whom open enrollment extended' do 
        let(:initial_application_state)       { :enrollment_extended }

        it "should close their open enrollment" do 
          (april_sponsors).each do |sponsor|
            benefit_application = sponsor.benefit_applications.first

            expect(sponsor.applicant?).to be_truthy
            expect(benefit_application.enrollment_extended?).to be_truthy

            sponsorship_service = subject.new(benefit_sponsorship: sponsor, new_date: benefit_application.open_enrollment_period.max.next_day)
            sponsorship_service.end_open_enrollment

            sponsor.reload
            benefit_application.reload

            expect(sponsor.applicant?).to be_truthy
            expect(benefit_application.enrollment_closed?).to be_truthy
          end
        end
      end

      context  'For renewal employers for whom open enrollment extended' do 
        let(:renewal_application_state)       { :enrollment_extended }

        it "should close their open enrollment" do 
          (april_renewal_sponsors).each do |sponsor|
            benefit_application = sponsor.benefit_applications.first

            expect(sponsor.active?).to be_truthy
            expect(benefit_application.enrollment_extended?).to be_truthy

            sponsorship_service = subject.new(benefit_sponsorship: sponsor, new_date: benefit_application.open_enrollment_period.max.next_day)
            sponsorship_service.end_open_enrollment

            sponsor.reload
            benefit_application.reload

            expect(sponsor.active?).to be_truthy
            expect(benefit_application.enrollment_eligible?).to be_truthy
          end
        end
      end
    end

   describe ".update_fein" do
    let(:benefit_sponsorship) { employer_organization.employer_profile.add_benefit_sponsorship }
    let(:exisitng_org) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)}
    let(:service_instance) { BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService.new(benefit_sponsorship: benefit_sponsorship)}
    let(:legal_name) { exisitng_org.legal_name }

    it "should update fein" do
      service_instance.update_fein("048459845")
      expect(benefit_sponsorship.organization.fein).to eq "048459845"
    end

     it "should not update fein" do
      exisitng_org.update_attributes(fein: "098735672")
      error_messages = service_instance.update_fein("098735672")
      expect(error_messages[0]).to eq false
      expect(error_messages[1].first).to eq ("FEIN matches HBX ID #{exisitng_org.hbx_id}, #{exisitng_org.legal_name}")
     end
   end

    describe ".transmit_renewal_carrier_drop_event" do
      let!(:benefit_market) { site.benefit_markets.first }
      let!(:benefit_market_catalog)  { benefit_market.benefit_market_catalogs.first }
      let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile_renewal_application, site: site)}
      let(:employer_profile) {organization.employer_profile}
      let(:benefit_package) { employer_profile.latest_benefit_application.benefit_packages.first }
      let!(:health_sponsored_benefit) {benefit_package.health_sponsored_benefit}
      let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
      let!(:renewal_application)  { employer_profile.renewal_benefit_application }
      let!(:active_application)  { employer_profile.active_benefit_application }
      let!(:active_application_product)  do
        FactoryBot.create(:benefit_markets_products_health_products_health_product,
                          application_period: TimeKeeper.date_of_record.beginning_of_year.last_year..TimeKeeper.date_of_record.end_of_year.last_year,
                          issuer_profile_id: issuer_profile.id)
      end
      let!(:new_renewal_app_product)  { FactoryBot.create(:benefit_markets_products_health_products_health_product)}
      let!(:update_benefit_application) do
        renewal_application.update_attributes!(aasm_state: :enrollment_eligible)
        active_application.benefit_packages.first.health_sponsored_benefit.update_attributes(reference_product_id: active_application_product.id, product_package_kind: :single_product)
        renewal_application.benefit_packages.first.health_sponsored_benefit.update_attributes(product_package_kind: :single_product)
        product = renewal_application.benefit_packages.first.health_sponsored_benefit.reference_product
        product.update_attributes(issuer_profile_id: issuer_profile.id)
      end

      let!(:service_instance)  { subject.new(benefit_sponsorship: employer_profile.active_benefit_sponsorship) }

      context "change in renewal application products" do
        before do
          sponsored_benefit = renewal_application.benefit_packages.first.health_sponsored_benefit
          sponsored_benefit.update_attributes(reference_product_id: new_renewal_app_product.id)
        end

        it "should notify carrier drop event" do
          expect(service_instance).to receive(:notify).with('acapi.info.events.employer.benefit_coverage_renewal_carrier_dropped', {employer_id: employer_profile.hbx_id, event_name: "benefit_coverage_renewal_carrier_dropped"})
          service_instance.transmit_renewal_carrier_drop_event
        end
      end

      context "NO change in renewal application products" do

        it "should not notify carrier drop event" do
          expect(service_instance).to receive(:notify).exactly(0).times
          service_instance.transmit_renewal_carrier_drop_event
        end
      end

    end

  end
end
