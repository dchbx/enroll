require 'rails_helper'

module SponsoredBenefits
  RSpec.describe BenefitApplications::BenefitApplication, type: :model, dbclean: :around_each do
    let(:subject) { BenefitApplications::BenefitApplication.new }

    # let(:date_range) { (Date.today..1.year.from_now) }

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

    context "#to_benefit_sponsors_benefit_application" do
      let(:benefit_application)       { SponsoredBenefits::BenefitApplications::BenefitApplication.new(params) }
      let(:benefit_sponsorship)       { SponsoredBenefits::BenefitSponsorships::BenefitSponsorship.new(
        benefit_market: "aca_shop_cca",
        enrollment_frequency: "rolling_month"
      )}

      let(:address)  { Address.new(kind: "primary", address_1: "609 H St NE", city: "Washington", state: "DC", zip: "20002", county: "County") }
      let(:phone  )  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
      let(:office_location) { OfficeLocation.new(
          is_primary: true,
          address: address,
          phone: phone
        )
      }
      let(:benefit_group)             { FactoryBot.create :benefit_group, title: 'new' }

      let(:benefit_market)      { site.benefit_markets.first }
      let(:current_effective_date)  { TimeKeeper.date_of_record }
      let!(:issuer_profile)  { FactoryBot.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}
      let!(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                             benefit_market: benefit_market,
                                             title: "SHOP Benefits for #{current_effective_date.year}",
                                             issuer_profile: issuer_profile,
                                             application_period: (effective_period_start_on.beginning_of_year..effective_period_start_on.end_of_year))

      }
      let!(:product)      { benefit_market_catalog.product_packages.where(package_kind: 'single_product').first.products.first}
      let!(:plan) {benefit_group.reference_plan}
      let!(:rating_area)   { FactoryBot.create_default :benefit_markets_locations_rating_area, active_year: effective_period_start_on.year }
      let!(:service_area)  { FactoryBot.create_default :benefit_markets_locations_service_area, active_year: effective_period_start_on.year }
      let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:benefit_sponsor_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:sponsor_benefit_sponsorship) { benefit_sponsor_organization.employer_profile.add_benefit_sponsorship }

      let(:plan_design_organization)  { SponsoredBenefits::Organizations::PlanDesignOrganization.new(legal_name: "xyz llc", office_locations: [office_location]) }
      let(:plan_design_proposal)      { SponsoredBenefits::Organizations::PlanDesignProposal.new(title: "New Proposal") }
      let(:profile) {SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new}

      before(:each) do
        plan.hios_id = product.hios_id
        plan.save
        sponsor_benefit_sponsorship.rating_area = rating_area
        sponsor_benefit_sponsorship.service_areas = [service_area]
        sponsor_benefit_sponsorship.save
        plan_design_organization.plan_design_proposals << [plan_design_proposal]
        plan_design_proposal.profile = profile
        profile.benefit_sponsorships = [benefit_sponsorship]
        benefit_sponsorship.benefit_applications = [benefit_application]
        benefit_application.benefit_groups << benefit_group
        plan_design_organization.save
      end

      it "should instantiate a plan year object and must have correct values assigned" do
        ben_app = benefit_application.to_benefit_sponsors_benefit_application(benefit_sponsor_organization)
        expect(ben_app.class).to eq BenefitSponsors::BenefitApplications::BenefitApplication
        expect(ben_app.benefit_packages.present?).to eq true
        expect(ben_app.start_on).to eq benefit_application.effective_period.begin
        expect(ben_app.end_on).to eq benefit_application.effective_period.end
        expect(ben_app.open_enrollment_start_on).to eq benefit_application.open_enrollment_period.begin
        expect(ben_app.open_enrollment_end_on).to eq benefit_application.open_enrollment_period.end
      end
    end
  end
end
