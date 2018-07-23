require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "activate_or_deactivate_employer_link_for_broker")

describe BuildShopEnrollment do

  let(:given_task_name) { "activate_or_deactivate_employer_link_for_broker" }
  subject { ActivateOrDeactivateEmpoyerLinkForBroker.new(given_task_name, double(:current_scope => nil)) }

  let!(:rating_area)                    { FactoryGirl.create_default :benefit_markets_locations_rating_area }
  let!(:service_area)                   { FactoryGirl.create_default :benefit_markets_locations_service_area }
  let!(:site)                           { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)                   { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)               { organization.employer_profile }
  let!(:broker_organization)            { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, site: site)}
  let!(:broker_agency_profile1)         { FactoryGirl.create(:benefit_sponsors_organizations_broker_agency_profile, organization: broker_organization, market_kind: 'shop', legal_name: 'Legal Name1') }
  let(:active_plan_design_organization) {
                                          SponsoredBenefits::Organizations::PlanDesignOrganization.new(
                                            owner_profile_id: broker_agency_profile1._id,
                                            sponsor_profile_id: employer_profile._id,
                                            office_locations: employer_profile.office_locations,
                                            fein: organization.fein,
                                            legal_name: organization.legal_name,
                                            has_active_broker_relationship: false,
                                            sic_code: employer_profile.sic_code
                                          )
                                        }
  let!(:organization2)                   { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile2)               { organization2.employer_profile }
  let!(:broker_organization2)            { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, site: site)}
  let!(:broker_agency_profile2)         { FactoryGirl.create(:benefit_sponsors_organizations_broker_agency_profile, organization: broker_organization2, market_kind: 'shop', legal_name: 'Legal Name1') }

  let(:inactive_plan_design_organization) {
                                            SponsoredBenefits::Organizations::PlanDesignOrganization.new(
                                              owner_profile_id: broker_agency_profile2._id,
                                              sponsor_profile_id: employer_profile2._id,
                                              office_locations: employer_profile2.office_locations,
                                              fein: organization2.fein,
                                              legal_name: organization2.legal_name,
                                              has_active_broker_relationship: true,
                                              sic_code: employer_profile2.sic_code
                                            )
                                          }

  describe "given a task name", dbclean: :after_each do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "given plan design organization", dbclean: :after_each do

    context "when both valid employer_profile feins is passed" do
      before :each do
        active_plan_design_organization.save!
        inactive_plan_design_organization.save!
        allow(ENV).to receive(:[]).with("activate_fein").and_return(organization.fein)
        allow(ENV).to receive(:[]).with("deactivate_fein").and_return(organization2.fein)
        subject.migrate
      end

      it "should successfully update plan_design_organization1" do
        active_plan_design_organization.reload
        expect(active_plan_design_organization.has_active_broker_relationship).to eq true
      end

      it "should successfully update plan_design_organization2" do
        inactive_plan_design_organization.reload
        expect(inactive_plan_design_organization.has_active_broker_relationship).to eq false
      end
    end

    context "when only one of the feins are valid" do
      before :each do
        active_plan_design_organization.save!
        allow(ENV).to receive(:[]).with("activate_fein").and_return(organization.fein)
        allow(ENV).to receive(:[]).with("deactivate_fein").and_return(broker_organization2.fein)
        subject.migrate
      end

      it "should successfully update plan_design_organization1" do
        active_plan_design_organization.reload
        expect(active_plan_design_organization.has_active_broker_relationship).to eq true
      end

      it "should not update plan_design_organization2" do
        expect(inactive_plan_design_organization.has_active_broker_relationship).to eq true
      end
    end

    context "when both invalid feins is passed" do
      before :each do
        allow(ENV).to receive(:[]).with("activate_fein").and_return(broker_organization.fein)
        allow(ENV).to receive(:[]).with("deactivate_fein").and_return(broker_organization2.fein)
        subject.migrate
      end

      it "should exit as there is no plan_design_organization for the given fein" do
        expect(active_plan_design_organization.has_active_broker_relationship).to eq false
      end

      it "should exit as there is no plan_design_organization for the given fein" do
        expect(inactive_plan_design_organization.has_active_broker_relationship).to eq true
      end
    end
  end
end
