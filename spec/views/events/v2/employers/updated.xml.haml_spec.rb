require 'rails_helper'
require File.join(Rails.root, "spec", "support", "acapi_vocabulary_spec_helpers")

RSpec.describe "events/v2/employer/updated.haml.erb" , dbclean: :after_each do

  describe "given a employer" , dbclean: :after_each do
    let!(:site)  { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, :with_benefit_market_catalog_and_product_packages, :cca) }
    let!(:benefit_market) { site.benefit_markets.first }
    let!(:benefit_market_catalog)  { benefit_market.benefit_market_catalogs.first }
    let(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization,:with_aca_shop_cca_employer_profile_initial_application, site:site)}
    let(:broker_agency_organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization,:with_site,:with_broker_agency_profile)}
    let(:mailing_address){ FactoryGirl.build(:benefit_sponsors_locations_address, kind: "mailing")}
    let(:mailing_office){ FactoryGirl.build(:benefit_sponsors_locations_office_location,address:mailing_address)}
    let(:employer_profile) {
      organization.employer_profile.office_locations <<  mailing_office
      organization.employer_profile
    }
    let(:benefit_application) { employer_profile.latest_benefit_application }
    let(:product_package) { benefit_market_catalog.product_packages.where(package_kind: :single_issuer).first }
    let!(:benefit_package) { FactoryGirl.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package) }
    let!(:health_sponsored_benefit) {benefit_package.health_sponsored_benefit}
    let!(:issuer_profile)  { FactoryGirl.create(:benefit_sponsors_organizations_issuer_profile) }
    let!(:update_products)  { product_package.products.update_all(issuer_profile:issuer_profile) }
    let(:sponsor_contribution) {FactoryGirl.create(:benefit_sponsors_sponsored_benefits_sponsor_contribution,product_package: product_package,sponsored_benefit:health_sponsored_benefit)}

    let!(:update_benefit) {
      benefit_application.aasm_state = :active
      health_sponsored_benefit.product_option_choice = product_package.products.first.issuer_profile.id
      health_sponsored_benefit.reference_product = product_package.products.first
      health_sponsored_benefit.sponsor_contribution = sponsor_contribution
      benefit_application.benefit_packages = [benefit_package]
      benefit_application.save
    }
    let!(:update_sponsored_benefit_products)  { health_sponsored_benefit.product_package.products.update_all(issuer_profile:issuer_profile, service_area_id:health_sponsored_benefit.recorded_service_area_ids.first) }
    let!(:broker_agency_profile) { broker_agency_organization.broker_agency_profile }
    let(:staff) { FactoryGirl.create(:person, :with_work_email, :with_work_phone)}
    let(:person_broker) {FactoryGirl.build(:person,:with_work_email, :with_work_phone)}
    let(:broker) {FactoryGirl.build(:broker_role,aasm_state:'active',person:person_broker)}
    let(:rating_area) { create(:rating_area, county_name: employer_profile.organization.primary_office_location.address.county, zip_code: employer_profile.organization.primary_office_location.address.zip)}
    let(:home_address)  { Address.new(kind: "home", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002") }
    let(:phone  )  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
    let(:mailing_address)  { Address.new(kind: "mailing", address_1: "609", city: "Washington", state: "DC", zip: "20002") }

    include AcapiVocabularySpecHelpers

    before(:all) do
      download_vocabularies
    end

    context "when manual gen of cv = false" do
      before :each do
        allow(employer_profile).to receive(:staff_roles).and_return([staff])
        allow(sponsor_contribution).to receive(:contribution_model).and_return(product_package.contribution_model)
        allow(employer_profile).to receive(:broker_agency_profile).and_return(broker_agency_profile)
        allow(broker_agency_profile).to receive(:active_broker_roles).and_return([broker])
        allow(broker_agency_profile).to receive(:primary_broker_role).and_return(broker)
        render :template => "events/v2/employers/updated", :locals => { :employer => employer_profile, manual_gen: false }
        @doc = Nokogiri::XML(rendered)
      end

      it "should have one plan year" do
        expect(@doc.xpath("//x:plan_years/x:plan_year", "x"=>"http://openhbx.org/api/terms/1.0").count).to eq 1
      end

      it "should have two office_location" do
        expect(@doc.xpath("//x:office_location", "x"=>"http://openhbx.org/api/terms/1.0").count).to eq 2
      end

      it "should have office location with address kind work" do
        expect(@doc.xpath("//x:office_locations/x:office_location[1]/x:address/x:type","x"=>"http://openhbx.org/api/terms/1.0").text).to eq "urn:openhbx:terms:v1:address_type#work"
      end

      it "should have office location with address kind mailing" do
        expect(@doc.xpath("//x:office_locations/x:office_location[2]/x:address/x:type","x"=>"http://openhbx.org/api/terms/1.0").text).to eq "urn:openhbx:terms:v1:address_type#mailing"
      end

      it "should have phone for mailing office location " do
        expect(@doc.xpath("//x:office_location[2]/x:phone/x:type", "x"=>"http://openhbx.org/api/terms/1.0").text).to eq "urn:openhbx:terms:v1:phone_type#work"
      end

      it "should have one broker_agency_profile" do
        expect(@doc.xpath("//x:broker_agency_profile", "x"=>"http://openhbx.org/api/terms/1.0").count).to eq 1
      end

      it "should have brokers in broker_agency_profile" do
        expect(@doc.xpath("//x:broker_agency_profile/x:brokers", "x"=>"http://openhbx.org/api/terms/1.0").count).to eq 1
      end

      it "should have contact email" do
        expect(@doc.xpath("//x:contacts/x:contact//x:emails//x:email//x:email_address", "x"=>"http://openhbx.org/api/terms/1.0").text).to eq staff.work_email_or_best
      end

      it "should not have shop_transfer" do
        expect(@doc.xpath("//x:shop_transfer/x:hbx_active_on", "x"=>"http://openhbx.org/api/terms/1.0").text).to eq ""
      end

      it "should be schema valid" do
        expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
      end
    end

    context "with dental plans" do

      # TODO No dental for MA fix for DC.

      # context "is_offering_dental? is true" do
      #
      #   before do
      #     dental_plan = FactoryGirl.create(:plan, name: "new dental plan", coverage_kind: 'dental',
      #                                      dental_level: 'high')
      #     benefit_group.elected_dental_plans = [dental_plan]
      #     benefit_group.dental_reference_plan_id = dental_plan.id
      #     plan_year.save!
      #   end
      #
      #   it "shows the dental plan in output" do
      #     render :template => "events/v2/employers/updated", :locals => {:employer => employer, manual_gen: false}
      #     expect(rendered).to include "new dental plan"
      #   end
      # end


      context "is_offering_dental? is false" do
        before do
          allow(sponsor_contribution).to receive(:contribution_model).and_return(product_package.contribution_model)
        end
        it "does not show the dental plan in output" do

          render :template => "events/v2/employers/updated", :locals => {:employer => employer_profile, manual_gen: false}
          expect(rendered).not_to include "new dental plan"
        end
      end
    end

    context "person of contact" do

      before do
        allow(employer_profile).to receive(:staff_roles).and_return([staff])
        allow(sponsor_contribution).to receive(:contribution_model).and_return(product_package.contribution_model)
      end
      it "should be included in xml" do
        render :template => "events/v2/employers/updated", :locals => {:employer => employer_profile, manual_gen: false}
        expect(rendered).to have_selector('contact', count: 1)
      end
    end

    context "POC address" do

      before do
        allow(employer_profile).to receive(:staff_roles).and_return([staff])
        allow(sponsor_contribution).to receive(:contribution_model).and_return(product_package.contribution_model)
        allow(staff).to receive(:addresses).and_return([mailing_address,home_address])
        render :template => "events/v2/employers/updated", :locals => {:employer => employer_profile, manual_gen: false}
        @doc = Nokogiri::XML(rendered)
      end

      it "should be included only poc mailing address" do
        expect(@doc.xpath("//x:contacts/x:contact/x:addresses", "x"=>"http://openhbx.org/api/terms/1.0").count).to eq 1
        expect(@doc.xpath("//x:contacts/x:contact/x:addresses/x:address/x:type", "x"=>"http://openhbx.org/api/terms/1.0").text).to eq "urn:openhbx:terms:v1:address_type#mailing"
      end
    end

    context "when manual gen of cv = true" do

      context "non termination case" do

        let!(:renewal_benefit_application){ FactoryGirl.create(:benefit_sponsors_benefit_application,:with_benefit_package, aasm_state: :enrollment_eligible)}
        let(:renewal_benefit_package){ renewal_benefit_application.benefit_packages.first}
        let!(:update_renewal){
          renewal_benefit_application.predecessor_application_id = benefit_application.id
          renewal_benefit_application.benefit_sponsor_catalog.product_packages.first.products.update_all(issuer_profile:issuer_profile, service_area_id: renewal_benefit_application.recorded_service_area_ids.first)
          active_benefit_sponsorship = employer_profile.active_benefit_sponsorship
          active_benefit_sponsorship.benefit_applications << renewal_benefit_application
          renewal_benefit_package.health_sponsored_benefit.product_option_choice = product_package.products.first.issuer_profile.id
          renewal_benefit_package.health_sponsored_benefit.reference_product = product_package.products.first
          renewal_benefit_package.health_sponsored_benefit.sponsor_contribution = sponsor_contribution
          active_benefit_sponsorship.save
        }

        before :each do
          allow(sponsor_contribution).to receive(:contribution_model).and_return(product_package.contribution_model)
          render :template => "events/v2/employers/updated", :locals => {:employer => employer_profile, manual_gen: true}
          @doc = Nokogiri::XML(rendered)
        end

        it "should return all eligible for export plan years" do
          expect(@doc.xpath("//x:plan_years/x:plan_year", "x" => "http://openhbx.org/api/terms/1.0").count).to eq 2
        end
      end

      context "terminated plan year with future termination date" do
        before :each do
          benefit_application.aasm_state = :terminated
          benefit_application.save
          allow(sponsor_contribution).to receive(:contribution_model).and_return(product_package.contribution_model)
          render :template => "events/v2/employers/updated", :locals => {:employer => employer_profile, manual_gen: true}
          @doc = Nokogiri::XML(rendered)
        end

        it "should return all eligible for export plan years" do
          expect(@doc.xpath("//x:plan_years/x:plan_year", "x" => "http://openhbx.org/api/terms/1.0").count).to eq 1
        end
      end
    end
  end
end
