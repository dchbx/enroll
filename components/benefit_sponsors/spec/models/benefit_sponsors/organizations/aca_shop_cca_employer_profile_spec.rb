require 'rails_helper'
require_relative '../../../concerns/observable_spec.rb'

module BenefitSponsors
  RSpec.describe Organizations::AcaShopCcaEmployerProfile, type: :model, dbclean: :after_each do
    it_behaves_like 'observable', nil, :with_organization_and_site

    let(:hbx_id)              { "56789" }
    let(:legal_name)          { "Tyrell Corporation" }
    let(:dba)                 { "Offworld Enterprises" }
    let(:fein)                { "100001001" }
    let(:entity_kind)         { :s_corporation }

    let(:configuration)       { BenefitMarkets::Configurations::Configuration.new }
    let(:benefit_market)      { ::BenefitMarkets::BenefitMarket.new(:kind => :aca_shop, title: "MA Health Connector SHOP", site_urn: "site_urn", description: "description") }
    let(:benefit_sponsorship) { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new }


    let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }

    # let!(:site)               { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_hbx_profile)}

    let(:organization)      { BenefitSponsors::Organizations::GeneralOrganization.new(
                                  site: site,
                                  hbx_id: hbx_id,
                                  legal_name: legal_name,
                                  dba: dba,
                                  fein: fein,
                                  entity_kind: entity_kind
                                )}

    let(:address)           { BenefitSponsors::Locations::Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002", county: "County") }
    let(:phone  )           { BenefitSponsors::Locations::Phone.new(kind: "main", area_code: "202", number: "555-9999") }
    let(:office_location)   { BenefitSponsors::Locations::OfficeLocation.new(is_primary: true, address: address, phone: phone) }
    let(:office_locations)  { [office_location] }

    let(:sic_code)          { '1111' }
    let(:rating_area)       { ::BenefitMarkets::Locations::RatingArea.new }


    let(:params) do
      {
        organization: organization,
        office_locations: office_locations,
        sic_code: sic_code
      }
    end

    context "A new model instance" do

      context "with no sic_code" do
        subject { described_class.new(params.except(:sic_code)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      # TODO: move this spec to appropriate model
      # context "with no rating_area" do
      #   subject { described_class.new(params.except(:rating_area)) }
      #   it "should not be valid" do
      #     subject.validate
      #     expect(subject).to_not be_valid
      #   end
      # end

      context "with all required arguments" do
        subject { described_class.new(params) }

        context "and all arguments are valid" do
          it "should be valid" do
            subject.validate
            expect(subject).to be_valid
          end

          it "should be able to access parent values for delegated attributes" do
            expect(subject.hbx_id).to eq hbx_id
            expect(subject.legal_name).to eq legal_name
            expect(subject.dba).to eq dba
            expect(subject.fein).to eq fein
          end

          it "should save and be findable" do
            subject.save!
            expect(described_class.find(subject.id)).to eq subject
          end
        end
      end
    end

    context "A BenefitSponsorship association", dbclean: :after_each do
      let(:site)                { BenefitSponsors::Site.new(site_key: :cca) }
      let(:benefit_market)      { ::BenefitMarkets::BenefitMarket.new(:kind => :aca_shop, title: "MA Health Connector SHOP") }
      let(:legal_name)          { "MA Health Connector" }
      let(:organization)        { BenefitSponsors::Organizations::GeneralOrganization.new(
                                      site: site,
                                      hbx_id: hbx_id,
                                      legal_name: legal_name,
                                      dba: dba,
                                      entity_kind: entity_kind,
                                      fein: "525285898",
                                    )}
      let(:profile)             { BenefitSponsors::Organizations::HbxProfile.new(organization: organization, office_locations: office_locations) }

      let(:tyrell_legal_name)   { "Tyrell Corporation" }
      let(:tyrell_fein)         { "100001001" }
      let(:wallace_legal_name)  { "Wallace Corporation" }
      let(:wallace_fein)        { "200001001" }
      let(:address)             { BenefitSponsors::Locations::Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002", county: "County") }
      let(:phone  )             { BenefitSponsors::Locations::Phone.new(kind: "main", area_code: "202", number: "555-9999") }
      let(:office_location)     { BenefitSponsors::Locations::OfficeLocation.new(is_primary: true, address: address, phone: phone) }
      let(:office_locations)    { [office_location] }
      let(:sic_code)            { '1111' }
      let(:rating_area)         { ::BenefitMarkets::Locations::RatingArea.new }



      let(:tyrell_organization)           { BenefitSponsors::Organizations::GeneralOrganization.create(
                                                site:         site,
                                                legal_name:   tyrell_legal_name,
                                                fein:         tyrell_fein,
                                                entity_kind:  entity_kind,
                                                profiles:     [tyrell_profile],
                                              )}

      let(:wallace_organization)          { BenefitSponsors::Organizations::GeneralOrganization.create(
                                                site:         site,
                                                legal_name:   wallace_legal_name,
                                                fein:         wallace_fein,
                                                entity_kind:  entity_kind,
                                                profiles:     [wallace_profile],
                                              )}

      let!(:tyrell_profile)                { described_class.new(
                                                office_locations: office_locations,
                                                sic_code:         sic_code,
                                            )}

      let!(:wallace_profile)               { described_class.new(
                                                office_locations: office_locations,
                                                sic_code: sic_code,
                                            )}

      before {
          site.owner_organization = organization
          site.site_organizations << organization
          organization.profiles << profile

          site.save
          organization.save
          benefit_market.save
          tyrell_organization.save
          wallace_organization.save
        }

      it "BenefitSponsorship should be findable" do
        tyrell_profile.add_benefit_sponsorship
        tyrell_profile.add_benefit_sponsorship
        tyrell_profile.add_benefit_sponsorship
        tyrell_profile.save

        wallace_profile.add_benefit_sponsorship
        wallace_profile.save

        expect((tyrell_profile.benefit_sponsorships).size).to eq 3
        expect((wallace_profile.benefit_sponsorships).size).to eq 1
      end


    end


    context "Embedded in a Plan Design Proposal" do
      let(:title)                     { 'New proposal' }
      let(:cca_employer_profile)      { BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new(sic_code: sic_code) }

      let(:plan_design_organization)  { Organizations::PlanDesignOrganization.new(fein: fein, legal_name: legal_name, sic_code: sic_code) }
      let(:plan_design_proposal)      { plan_design_organization.plan_design_proposals.build(title: title, profile: cca_employer_profile) }
      let(:profile)                   { plan_design_organization.plan_design_proposals.first.profile }

      it "should save without error"
      it "should be findable"

    end

    context "for active_broker" do
      let(:benefit_sponsor)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:employer_profile100)    { benefit_sponsor.employer_profile }
      let(:benefit_sponsorship100)    { employer_profile100.add_benefit_sponsorship }
      let(:broker_agency_profile) { FactoryGirl.create(:benefit_sponsors_organizations_broker_agency_profile, assigned_site: site) }
      let!(:broker_agency_account) { FactoryGirl.build(:benefit_sponsors_accounts_broker_agency_account, benefit_sponsorship: benefit_sponsorship100, broker_agency_profile: broker_agency_profile) }

      it "should return person record" do
        expect(employer_profile100.active_broker).to eq broker_agency_account.writing_agent.person
      end

      it "should return nothing if broker is not assigned to employer_profile" do
        benefit_sponsorship100.broker_agency_accounts = []
        benefit_sponsorship100.save
        expect(employer_profile100.active_broker.present?).to be_falsey
      end
    end
  end
end
