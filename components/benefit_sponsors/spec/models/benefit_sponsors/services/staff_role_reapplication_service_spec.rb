# frozen_string_literal: true

require 'rails_helper'

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::StaffRoleReapplicationService, type: :model, :dbclean => :after_each do

    let(:site)                                  { FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }

    let!(:broker_organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let(:broker_agency_profile)                 { broker_organization.broker_agency_profile }
    let(:primary_broker_role)                   { broker_agency_profile.primary_broker_role }

    let!(:broker_person)                        { primary_broker_role.person }

    let(:general_agency_organization)           { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
    let(:general_agency_profile)                { general_agency_organization.general_agency_profile }
    let(:primary_general_agency_staff_role)     { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, is_primary: true, aasm_state: 'denied') }
    let!(:ga_person)                            { primary_general_agency_staff_role.person }

    describe ".re_apply" do

      shared_examples_for "broker re-application" do |from_state, to_state|

        before :each do
          primary_broker_role.update_attributes!(aasm_state: from_state)
          service = ::BenefitSponsors::Services::StaffRoleReapplicationService.new({profile_id: broker_agency_profile.id, person_id: broker_person.id})
          service.re_apply
        end

        it "should transition from #{from_state} to #{to_state}" do
          primary_broker_role.reload
          expect(primary_broker_role.aasm_state).to eq to_state
        end
      end

      context "Broker Agency" do
        it_behaves_like 'broker re-application', 'denied', 'application_extended'
        it_behaves_like 'broker re-application', 'broker_agency_pending', 'application_extended'
      end

      shared_examples_for "general agency re-application" do |from_state, to_state|

        before :each do
          primary_general_agency_staff_role.update_attributes!(aasm_state: from_state)
          service = ::BenefitSponsors::Services::StaffRoleReapplicationService.new({profile_id: general_agency_profile.id, person_id: ga_person.id})
          service.re_apply
        end

        it "should transition from #{from_state} to #{to_state}" do
          primary_general_agency_staff_role.reload
          expect(primary_general_agency_staff_role.aasm_state).to eq to_state
        end
      end

      context "General Agency" do
        it_behaves_like 'general agency re-application', 'denied', 'applicant'
        it_behaves_like 'general agency re-application', 'decertified', 'applicant'
      end
    end
  end
end
