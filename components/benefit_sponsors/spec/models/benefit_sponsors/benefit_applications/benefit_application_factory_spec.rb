require 'rails_helper'
require File.join(File.dirname(__FILE__), "..", "..", "..", "support/benefit_sponsors_site_spec_helpers")

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplicationFactory, type: :model, :dbclean => :after_each do

    describe "constructor" do
      let(:site)  { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:employer_profile)    { organization.employer_profile }
      let(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }

      let!(:dc_benefit_application) {BenefitApplications::BenefitApplication.new}
      let!(:cca_benefit_application) {BenefitApplications::BenefitApplication.new}
      let!(:dc_args) {{"fte_count" => "5"}}
      let!(:cca_args) {{"recorded_sic_code" => "0113"}}

      context "for dc" do 
        it "should assign dc attributes to given benefit applcation" do
          expect(BenefitApplications::BenefitApplication).to receive(:new).and_return(dc_benefit_application)
          expect(dc_benefit_application.fte_count).to eq 0
          BenefitApplications::BenefitApplicationFactory.new(benefit_sponsorship, dc_args)
          expect(dc_benefit_application.benefit_sponsorship).to eq benefit_sponsorship
          expect(dc_benefit_application.fte_count).to eq 5
        end
      end

      context "for cca" do 
        it "should assign cca attributes to given benefit application" do
          expect(BenefitApplications::BenefitApplication).to receive(:new).and_return(cca_benefit_application)
          expect(cca_benefit_application.recorded_sic_code).to be_nil
          benefit_sponsorship.benefit_market.update_attributes(site_urn: :cca)
          BenefitApplications::BenefitApplicationFactory.new(benefit_sponsorship, cca_args)
          expect(cca_benefit_application.benefit_sponsorship).to eq benefit_sponsorship
          expect(cca_benefit_application.recorded_sic_code).to eq "0113"
        end
      end
    end
  end
end
