require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_initial_invoice_title")

describe UpdateInitialInvoiceTitle, dbclean: :after_each do

  let(:given_task_name) { "update_initial_invoice_title" }
  subject { UpdateInitialInvoiceTitle.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update initial invoice title", dbclean: :after_each do

    let!(:benefit_markets_location_rating_area) { FactoryBot.create_default(:benefit_markets_locations_rating_area) }
    let!(:benefit_markets_location_service_area) { FactoryBot.create_default(:benefit_markets_locations_service_area) }
    let!(:security_question)  { FactoryBot.create_default :security_question }
    let(:current_effective_date)  { TimeKeeper.date_of_record }
    let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }

    let(:benefit_market)      { site.benefit_markets.first }
    let!(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                            benefit_market: benefit_market,
                                            issuer_profile: issuer_profile,
                                            title: "SHOP Benefits for #{current_effective_date.year}",
                                            application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
                                          }

    let(:organization)        { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)    { organization.employer_profile }
    let(:benefit_sponsorship) do
      sponsorship = employer_profile.add_benefit_sponsorship
      sponsorship.save
      sponsorship
    end
    let!(:benefit_sponsorship_id) { benefit_sponsorship.id.to_s }

    let(:form_class)  { BenefitSponsors::Forms::BenefitPackageForm }
    let(:person) { FactoryBot.create(:person) }
    let!(:user) { FactoryBot.create :user, person: person}
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }

    let!(:benefit_application) {
      application = FactoryBot.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship)
      application.benefit_sponsor_catalog.save!
      application
    }
    let!(:benefit_application_id) { benefit_application.id.to_s }
    let!(:issuer_profile)  { FactoryBot.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}
    let!(:product_package_kind) { :single_issuer }
    let!(:product_package) { benefit_market_catalog.product_packages.where(package_kind: product_package_kind).first }

    let(:product) { product_package.products.first }

    let(:sbc_document) {
      ::Document.new({
        title: 'sbc_file_name', subject: "SBC",
        :identifier=>"urn:openhbx:terms:v1:file_storage:s3:bucket:#{Settings.site.s3_prefix}-enroll-sbc-test#7816ce0f-a138-42d5-89c5-25c5a3408b82"
        })
    }

    let!(:benefit_package) { FactoryBot.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package) }

    let(:initial_invoice) {organization.employer_profile.documents.new({ title: "SomeTitle",
      date: TimeKeeper.date_of_record,
      creator: "hbx_staff",
      subject: "initial_invoice",
      identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:#bucket_name#key",
      format: "file_content_type"
    })}

    before do
      initial_invoice.save!
      organization.employer_profile.documents << initial_invoice
      organization.save!
    end

    it "should update the initial invoice title" do
      subject.migrate
      initial_invoice.reload
      expect(initial_invoice.title).to eq "Initial_Invoice_Now_Available.pdf"
    end
  end
end
