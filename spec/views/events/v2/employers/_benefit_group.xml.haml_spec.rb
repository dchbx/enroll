require 'rails_helper'

describe "app/views/events/v2/employers/_benefit_group.xml.haml" , dbclean: :after_each do
  let!(:site)  { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, :with_benefit_market_catalog_and_product_packages, :cca) }
  let!(:benefit_market) { site.benefit_markets.first }
  let!(:benefit_market_catalog)  { benefit_market.benefit_market_catalogs.first }
  let(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization,:with_aca_shop_cca_employer_profile_initial_application, site:site)}
  let(:employer_profile) {organization.employer_profile}
  let(:benefit_package) { employer_profile.latest_benefit_application.benefit_packages.first }
  let!(:health_sponsored_benefit) {benefit_package.health_sponsored_benefit}

  context "benefit_group xml" do
    context "reference plan" do
      before :each do
        render :template => "events/v2/employers/_benefit_group.xml.haml", locals: {benefit_group: benefit_package,
                                                                                    elected_plans: [], relationship_benefits: [],sponsored_benefit:health_sponsored_benefit}
        @doc = Nokogiri::XML(rendered)
      end

      it "does not include reference plan" do
        expect(@doc.xpath("//reference_plan").count).to eq(0)
      end
    end
  end
end
