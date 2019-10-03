require 'rails_helper'
require_relative '../../../concerns/observable_spec.rb'

module BenefitSponsors
  RSpec.describe Organizations::Organization, type: :model, dbclean: :after_each do
    it_behaves_like 'observable', :benefit_sponsors_organizations_general_organization, :with_site, :with_aca_shop_cca_employer_profile

    context "an Organization is hierarchical with a top level agency and child divisions" do
      let(:agency_name)             { "Multinational Conglomerate, Ltd" }
      let(:business_division_name)  { "Business Ops" }
      let(:it_division_name)        { "Information Technology Ops" }
      let(:it_devops_division_name) { "DevOps" }
      let(:agency)                  { BenefitSponsors::Organizations::ExemptOrganization.new(legal_name: agency_name) }
      let(:it_division)             { BenefitSponsors::Organizations::ExemptOrganization.new(legal_name: it_division_name) }

      before do
        agency.divisions.build(legal_name: business_division_name)
        agency.divisions << it_division
        it_division.divisions.build(legal_name: it_devops_division_name)
      end

      it "the top level Agency should have two divisions" do
        expect(agency.divisions.size).to eq 2
      end

      it "IT division should have one division" do
        expect(it_division.divisions.first.legal_name).to eq it_devops_division_name
      end

      it "the IT devops division should have two agency parents" do
        expect(it_division.divisions.first.agency.legal_name).to eq it_division_name
        expect(it_division.divisions.first.agency.agency.legal_name).to eq agency_name
        expect(it_division.divisions.first.agency.agency.agency).to be_nil
      end
    end


    context "a broker gains access to an employer's information for plan_design" do
      let(:employer_name)           { "Classy Cupcakes, Corp" }
      let(:broker_name)             { "Busy Brokers, Inc" }
      let!(:employer_organization)  { BenefitSponsors::Organizations::ExemptOrganization.new(legal_name: employer_name) }
      let!(:broker_organization)    { BenefitSponsors::Organizations::ExemptOrganization.new(legal_name: broker_name) }

      before { broker_organization.plan_design_subjects << employer_organization }

      it "the employer should appear in the broker's subject list" do
        expect((broker_organization.plan_design_subjects).size).to eq 1
        expect(broker_organization.plan_design_subjects.first).to eq employer_organization
      end

      # it "the broker should appear in the employer's author list" do
      #   expect((employer_organization.plan_design_authors).size).to eq 1
      #   expect(employer_organization.plan_design_authors.first).to eq broker_organization
      # end

      it "the broker should appear in the employer's author ID list" do
        expect((employer_organization.plan_design_author_ids).size).to eq 1
        expect(employer_organization.plan_design_author_ids.first).to eq broker_organization.id
      end

      context "and the broker creates a plan_design_organization for the employer" do
        let(:customer)                  { broker_organization.plan_design_subjects.first }
        let!(:plan_design_organization) { broker_organization.plan_design_organizations.build(subject_organization: customer) }

        it "the broker should have a new plan_design_organization instance" do
          expect(broker_organization.plan_design_organizations.first).to eq plan_design_organization
        end

        it "and the new plan_design_organization instance should reference the employer's (subject) organization" do
          expect(broker_organization.plan_design_organizations.first.subject_organization).to eq customer
        end
      end
    end


    context "a health exchange sets up a site offering ACA individual and shop benefit markets" do
      let(:shop_kind)           { :aca_shop }
      # let(:individual_kind)     { :aca_individual }
      let(:hbx_name)            { "Health Exchange Unlimited, LTD" }
      let(:entity_kind)         { :s_corporation }

      let(:hbx_site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:shop_benefit_market)  { hbx_site.benefit_markets.first }

      it "a site should exist with an individual and shop market" do
        expect(hbx_site.benefit_markets.size).to eq 1
      end

      context "and an employer sponsors benefits" do
        let(:employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: hbx_site) }
        let(:employer_profile)        { employer_organization.employer_profile }

        before { employer_organization.sponsor_benefits_for(employer_profile) }

        it "should add a benefit_sponsorship to the organization" do
          expect(employer_organization.benefit_sponsorships.size).to eq 1
        end

        it "benefit sponsorship should be associated with the correct profile" do
          expect(employer_organization.benefit_sponsorships.first.profile).to eq employer_profile
        end

        it "benefit sponsorship should be associated with the correct benefit market" do
          expect(employer_organization.benefit_sponsorships.first.benefit_market).to eq shop_benefit_market
        end

      end

    end

    context "search for broker agencies" do
      let!(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:organization_with_hbx_profile)  { site.owner_organization }
      let!(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
      let!(:broker_agency_profile1) { organization.broker_agency_profile }

      let!(:second_organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
      let!(:second_broker_agency_profile) { second_organization.broker_agency_profile }
      let!(:subject) { BenefitSponsors::Organizations::Organization }
      let!(:new_person_for_staff) { FactoryBot.create(:person) }
      let!(:broker_role) { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile1.id, person: new_person_for_staff) }


      let(:bap_id) { organization.broker_agency_profile.id }

      context "search for broker agencies from employer portal" do

        before do
          organization.update_attributes(legal_name: 'org1')
          broker_agency_profile1.update_attributes(aasm_state: 'is_approved')
        end

        it "should return searched broker agency profile" do
          search_params = {q: organization.legal_name}
          expect(subject.broker_agencies_with_matching_agency_or_broker(search_params, nil).count). to eq 1
          expect(subject.broker_agencies_with_matching_agency_or_broker(search_params, nil).first.legal_name). to eq organization.legal_name
        end

        it "should return all broker agency profiles if no search string is passed" do
          second_organization.update_attributes(legal_name: 'org2')
          second_broker_agency_profile.update_attributes(aasm_state: 'is_approved')
          search_params = {q: ''}
          expect(subject.broker_agencies_with_matching_agency_or_broker(search_params, nil).count). to eq 2
          expect(subject.broker_agencies_with_matching_agency_or_broker(search_params, nil).first.legal_name). to eq organization.legal_name
        end

      end

      context "search for broker agencies from broker staff portal" do

        before do
          organization.update_attributes(legal_name: 'org1')
          broker_agency_profile1.update_attributes(aasm_state: 'is_approved')
        end

        it "should return searched broker agency profile" do
          search_params = {q: organization.legal_name}
          expect(subject.broker_agencies_with_matching_agency_or_broker(search_params, true).count). to eq 1
          expect(subject.broker_agencies_with_matching_agency_or_broker(search_params, true).first.legal_name). to eq organization.legal_name
        end

        it "should not return any broker agency profiles if no search string is passed" do
          second_organization.update_attributes(legal_name: 'org2')
          second_broker_agency_profile.update_attributes(aasm_state: 'is_approved')
          search_params = {q: ''}
          expect(subject.broker_agencies_with_matching_agency_or_broker(search_params, true).count). to eq 0
        end
      end
    end

    context "search for general agencies" do
      let!(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:organization_with_hbx_profile)  { site.owner_organization }
      let!(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
      let!(:general_agency_profile1) { organization.general_agency_profile }

      let!(:second_organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
      let!(:second_general_agency_profile) { second_organization.general_agency_profile }
      let!(:subject) { BenefitSponsors::Organizations::Organization }
      let!(:new_person_for_staff) { FactoryBot.create(:person) }
      let!(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile1.id, person: new_person_for_staff, is_primary: true) }
      let(:gap_id) { organization.broker_agency_profile.id }

      context "search for general agencies from ga staff portal" do

        before do
          organization.update_attributes(legal_name: 'org1')
          general_agency_profile1.update_attributes(aasm_state: 'is_approved')
        end

        it "should return searched general agency profile" do
          search_params = {q: organization.legal_name}
          expect(subject.general_agencies_with_matching_ga(search_params, true).count). to eq 1
          expect(subject.general_agencies_with_matching_ga(search_params, true).first.legal_name). to eq organization.legal_name
        end

        it "should not return any broker agency profiles if no search string is passed" do
          second_organization.update_attributes(legal_name: 'org2')
          second_general_agency_profile.update_attributes(aasm_state: 'is_approved')
          search_params = {q: ''}
          expect(subject.broker_agencies_with_matching_agency_or_broker(search_params, true).count). to eq 0
        end
      end
    end
  end
end
