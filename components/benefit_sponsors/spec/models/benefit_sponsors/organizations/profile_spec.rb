require 'rails_helper'

module BenefitSponsors
  RSpec.describe Organizations::Profile, type: :model do

    let(:hbx_id)            { "56789" }
    let(:legal_name)        { "Tyrell Corporation" }
    let(:dba)               { "Offworld Enterprises" }
    let(:fein)              { "100001001" }
    let(:entity_kind)       { :c_corporation }
    let(:contact_method)    { :paper_and_electronic }

    let!(:site)             { BenefitSponsors::Site.new(site_key: :dc) }
    let(:organization)      { BenefitSponsors::Organizations::GeneralOrganization.new(
                                site: site,
                                hbx_id: hbx_id,
                                legal_name: legal_name,
                                dba: dba,
                                entity_kind: entity_kind,
                                fein: fein,
    )}

    let(:address)           { BenefitSponsors::Locations::Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002", county: "County") }
    let(:phone  )           { BenefitSponsors::Locations::Phone.new(kind: "main", area_code: "202", number: "555-9999") }
    let(:office_location)   { BenefitSponsors::Locations::OfficeLocation.new(is_primary: true, address: address, phone: phone) }
    let(:office_locations)  { [office_location] }


    let(:params) do
      {
        organization: organization,
        office_locations: office_locations,
        contact_method: contact_method,
      }
    end

    context "A new model instance" do
      context "with no organization" do
        subject { described_class.new(params.except(:organization)) }

        it "should not be valid" do
          subject.validate
          expect{subject.save!}.to raise_error(Mongoid::Errors::NoParent)
        end
      end

      # Contact method set by default in the model
      context "with no contact_method" do
        subject { described_class.new(params.except(:contact_method)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to be_valid
        end

        context "or contact method is invalid" do
          let(:invalid_contact_method)  { :snapchat }

          before { subject.contact_method = invalid_contact_method }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
          end
        end
      end

      context "with no office_locations" do
        subject { described_class.new(params.except(:office_locations)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "without a primary office location" do
        let(:invalid_address)         { BenefitSponsors::Locations::Address.new(kind: "work", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002", county: "County") }
        let(:invalid_office_location) { BenefitSponsors::Locations::OfficeLocation.new(is_primary: false, address: invalid_address, phone: phone) }

        subject { described_class.new(office_locations: [invalid_office_location] ) }

        it "should not be valid"
      end

      context "with all required arguments", dbclean: :after_each do
        subject { described_class.new(params) }

        it "is_benefit_sponsorship_eligible attribute should default to false" do
          expect(subject.is_benefit_sponsorship_eligible).to eq false
        end

        context "and all arguments are valid" do
          before {
            site.byline = 'test'
            site.long_name = 'test'
            site.short_name = 'test'
            site.domain_name = 'test'
            site.owner_organization = organization
            site.site_organizations << organization
            organization.profiles << subject
          }

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
            expect(site.save!).to eq true
            expect(organization.save!).to eq true

            expect(subject.save!).to eq true
            expect(BenefitSponsors::Organizations::Profile.find(subject.id)).to eq subject
          end

        end
      end

      context "local delegated attributes are updated" do
        subject { described_class.new(params) }

        let(:changed_legal_name)    { "Wallace Corporation" }
        let(:changed_dba)           { "Offworld Adventures" }
        let(:changed_fein)          { "200002002" }

        before do
          subject.legal_name  = changed_legal_name
          subject.dba         = changed_dba
          subject.fein        = changed_fein
        end

        it "should update attribute values on the parent model" do
          expect(subject.organization.legal_name).to eq changed_legal_name
          expect(subject.organization.dba).to eq changed_dba
          expect(subject.organization.fein).to eq changed_fein
        end
      end
    end


    context "Adding an initial BenefitSponsorship" do

      context "and an initial BenefitSponsorship is added" do

        it "" do
        end

        context "and it is saved" do
        end

      end

    end

    context "Adding a second or greater BenefitSponsorship" do

      context "and the prior BenefitSponsorship was canceled without effectuating enrollment" do

        context "and the benefit_application effective date is one date after the cancelation date" do
          it "should be valid"
        end

        context "and the benefit_application effective date is later than one day after the cancelation date" do
          it "should be valid"
        end

        context "and the benefit_application effective date is earlier than the most recent benefit_application cancelation" do
          it "should be valid"
        end
      end

      context "and the prior BenefitSponsorship was terminated after effectuating enrollment" do

        context "and the benefit_application effective date is one date after the termination date" do
        end

        context "and the benefit_application effective date is later than one day after the termination date" do
        end

        context "and the benefit_application effective date is earlier than the most recent benefit_application termination" do
          it "should be invalid"
        end
      end


      it "should become the new active benefit_sponsorship"

      it "the former benefit_sponsorship end date should be set and state transitioned"

      it "benefit with sponsored benefit has date gap sponsored_benefits then we need a new benefit_sponsorship"

      context "and BenefitSponsorship is canceled " do
      end
    end

    context "Sponsor moves primary office" do
      let(:profile)             { described_class.new(params) }
      let(:benefit_sponsorship) { profile.add_benefit_sponsorship }

      it "notifies benefit_sponsorships with :primary_office_location_change event" do
        profile.is_benefit_sponsorship_eligible = true
        expect(benefit_sponsorship).to receive(:profile_event_subscriber).with(:primary_office_location_change)
        profile.primary_office_location.address.address_1 = "SOME OTHER STREET"
        profile.primary_office_location.save!
      end

    end

    # let(:is_benefit_sponsorship_eligible) { true }
    # let(:sponsorship_profile)             { BenefitSponsors::Organizations::AcaShopDcEmployerProfile.new }
    # let(:benefit_market)                  { BenefitMarkets::BenefitMarket.new(:kind => :aca_shop, title: "DC Health SHOP", site: site) }
    # let(:contact_method_kind)             { :paper_and_electronic }



  end
end
