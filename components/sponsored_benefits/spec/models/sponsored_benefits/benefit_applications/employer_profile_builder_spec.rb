require 'rails_helper'

module SponsoredBenefits
  RSpec.describe BenefitApplications::EmployerProfileBuilder, type: :model do
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

    context "add_benefit_sponsors_benefit_application" do
      let(:benefit_application)       { SponsoredBenefits::BenefitApplications::BenefitApplication.new(params) }
      let(:benefit_sponsorship)       { SponsoredBenefits::BenefitSponsorships::BenefitSponsorship.new(
        benefit_market: "aca_shop_cca",
        enrollment_frequency: "rolling_month"
      )}

      let(:address)  { Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002", county: "County") }
      let(:phone  )  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
      let(:office_location) { OfficeLocation.new(
          is_primary: true,
          address: address,
          phone: phone
        )
      }

      let(:benefit_market)      { site.benefit_markets.first }
      let(:current_effective_date)  { TimeKeeper.date_of_record }
      let!(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                              benefit_market: benefit_market,
                                              title: "SHOP Benefits for #{current_effective_date.year}",
                                              application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
                                      }
      let!(:rating_area)   { FactoryGirl.create_default :benefit_markets_locations_rating_area }
      let!(:service_area)  { FactoryGirl.create_default :benefit_markets_locations_service_area }
      let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:benefit_sponsor_organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:sponsor_benefit_sponsorship) { benefit_sponsor_organization.employer_profile.add_benefit_sponsorship }

      let(:plan_design_organization)  { SponsoredBenefits::Organizations::PlanDesignOrganization.new(legal_name: "xyz llc", office_locations: [office_location]) }
      let(:plan_design_proposal)      { SponsoredBenefits::Organizations::PlanDesignProposal.new(title: "New Proposal") }
      let(:profile) {SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new}

      let(:product)  { FactoryGirl.create :benefit_markets_products_health_products_health_product }
      let(:plan )    { FactoryGirl.create(:plan, hios_id: product.hios_id) }
      let(:benefit_group)             { FactoryGirl.create(:benefit_group, reference_plan_id: plan.id) }

      before(:each) do
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

      it "should successfully add plan year to employer profile with published quote" do
        plan_design_proposal.publish!
        builder = SponsoredBenefits::BenefitApplications::EmployerProfileBuilder.new(plan_design_proposal, benefit_sponsor_organization)
        expect(benefit_sponsor_organization.active_benefit_sponsorship.benefit_applications.present?).to eq false
        builder.add_benefit_sponsors_benefit_application
        expect(benefit_sponsor_organization.active_benefit_sponsorship.benefit_applications.present?).to eq true
      end
    end
  end
end
