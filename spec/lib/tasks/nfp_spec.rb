require 'rails_helper'
Rake.application.rake_require "tasks/nfp"
include ActiveJob::TestHelper
Rake::Task.define_task(:environment)

RSpec.describe 'upload the invoice to s3', :type => :task, dbclean: :after_each do

  let!(:benefit_markets_location_rating_area) { FactoryGirl.create_default(:benefit_markets_locations_rating_area) }
  let!(:benefit_markets_location_service_area) { FactoryGirl.create_default(:benefit_markets_locations_service_area) }
  let!(:security_question)  { FactoryGirl.create_default :security_question }
  let(:current_effective_date)  { TimeKeeper.date_of_record }
  let(:start_on)                { current_effective_date.prev_month.beginning_of_month }
  let(:effective_period)        { start_on..start_on.next_year.prev_day }
  let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }

  let(:benefit_market)      { site.benefit_markets.first }
  let!(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                          benefit_market: benefit_market,
                                          title: "SHOP Benefits for #{current_effective_date.year}",
                                          application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
                                        }
  let!(:organization)        { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site, hbx_id: "211045") }
  let!(:file_path) { "spec/test_data/invoices/211045_12062017_INVOICE_R.pdf" }
  let(:employer_profile)    { organization.employer_profile }
  let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
  let(:benefit_sponsorship) do
    FactoryGirl.create(
      :benefit_sponsors_benefit_sponsorship,
      :with_rating_area,
      :with_service_areas,
      supplied_rating_area: benefit_markets_location_rating_area,
      service_area_list: [benefit_markets_location_service_area],
      organization: organization,
      profile_id: organization.profiles.first.id,
      benefit_market: site.benefit_markets[0],
      employer_attestation: employer_attestation) 
  end
  let!(:benefit_application) {
    application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, aasm_state: :active, effective_period: effective_period)
    application.benefit_sponsor_catalog.save!
    application
  }
  let(:service)             { BenefitSponsors::Services::UploadDocumentsToProfilesService.new }

  context "Upload the notice to s3" do
    it "file invoice file exists it should upload document" do
      allow(service).to receive(:upload_invoice_to_employer_profile).with(file_path, "211045_12062017_INVOICE_R.pdf").and_return nil
      Rake::Task['nfp:invoice_upload'].invoke('spec/test_data/invoices/')
      organization.reload
      expect(organization.employer_profile.invoices.count).to eq 1
    end

    it "should not upload when no file is exists in direcotry" do
      Rake::Task['nfp:invoice_upload'].invoke('spec/test_data/user_name/')
      organization.reload
      expect(organization.employer_profile.invoices.count).to eq 0
    end

  end
end

