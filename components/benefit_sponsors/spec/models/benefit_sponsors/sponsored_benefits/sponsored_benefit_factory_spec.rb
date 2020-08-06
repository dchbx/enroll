# frozen_string_literal: true

require "rails_helper"

RSpec.describe do
  describe "#initialize_sponsored_benefit", dbclean: :after_each do

    let(:site)                  { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:benefit_sponsor)        { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile_initial_application, site: site) }
    let(:benefit_sponsorship)    { benefit_sponsor.active_benefit_sponsorship }
    let(:benefit_application)    { benefit_sponsorship.benefit_applications.first }
    let(:benefit_package)    { benefit_application.benefit_packages.first }

    let(:current_effective_date)  { TimeKeeper.date_of_record }
    let(:benefit_market)      { site.benefit_markets.first }
    let(:benefit_market_catalog) do
      create(:benefit_markets_benefit_market_catalog, :with_product_packages,
             benefit_market: benefit_market,
             title: "SHOP Benefits for #{current_effective_date.year}",
             application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
    end
    let(:issuer_profile)  { FactoryBot.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}
    let(:product_package_kind) { :single_product}
    let!(:product_package) { benefit_market_catalog.product_packages.where(package_kind: product_package_kind).first }

    let(:attrs) do
      {
        :product_package_kind => product_package_kind,
        :sponsor_contribution_attributes => {
          :contribution_levels_attributes => contribution_levels_attributes
        }
      }
    end

    let(:contribution_levels_attributes) do
      [
        {:is_offered => "true", :display_name => "Employee", :contribution_factor => "95" },
        {:is_offered => "true", :display_name => "Spouse", :contribution_factor => "85" },
        {:is_offered => "true", :display_name => "Domestic Partner", :contribution_factor => "75" },
        {:is_offered => "true", :display_name => "Child Under 26", :contribution_factor => "75" }
      ]
    end

    context "when kind is dental" do

      let(:subject) { BenefitSponsors::SponsoredBenefits::SponsoredBenefitFactory.new(benefit_package, attrs) }

      before :each do
        attrs.merge!({
                       kind: "dental"
                     })
      end

      it "should initialize dental sponsored benefit" do
        expect(subject.sponsored_benefit.class).to eq BenefitSponsors::SponsoredBenefits::DentalSponsoredBenefit
      end

      it "should have linked package" do
        expect(subject.sponsored_benefit.benefit_package).to eq benefit_package
      end

      it "should have sponsor contribution" do
        expect(subject.sponsored_benefit.sponsor_contribution.class).to eq BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution
      end

      it "should have contribution levels" do
        expect(subject.sponsored_benefit.sponsor_contribution.contribution_levels.first.class).to eq BenefitSponsors::SponsoredBenefits::ContributionLevel
      end
    end
  end

  describe "#update_sponsored_benefit" do

    context "when kind is dental" do
      it "should update dental sponsored benefit" do
      end

      it "should have linked package" do
      end

      it "should have sponsor contribution" do
      end

      it "should have contribution levels" do
      end
    end
  end
end
