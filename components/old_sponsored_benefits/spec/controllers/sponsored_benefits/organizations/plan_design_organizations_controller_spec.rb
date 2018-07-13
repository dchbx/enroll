require 'rails_helper'

module DataTablesAdapter
end
module Config::AcaConcern
end

USER_ROLES = [:with_hbx_staff_role, :without_hbx_staff_role]

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignOrganizationsController, type: :controller, dbclean: :around_each  do
    routes { SponsoredBenefits::Engine.routes }

    let(:valid_session) { {} }
    let(:current_person) { double(:current_person) }
    let(:active_user) { double(:active_user) }
    let(:employer) { double(:employer, id: "11111", name: 'ABC Company', sic_code: '0197') }
    let(:broker) { double(:broker, id: 2) }
    let(:broker_role) { double(:broker_role, id: 3) }
    let(:broker_agency_profile_id) { "216735" }
    let(:broker_agency_profile) { double(:sponsored_benefits_broker_agency_profile, id: broker_agency_profile_id, persisted: true, fein: "5555", hbx_id: "123312",
                                    legal_name: "ba-name", dba: "alternate", is_active: true, organization: plan_design_organization) }
    let(:old_broker_agency_profile) { build(:sponsored_benefits_broker_agency_profile) }
    let!(:plan_design_organization) { create(:plan_design_organization, sponsor_profile_id: employer.id,
                                                                        owner_profile_id: broker_agency_profile_id,
                                                                        legal_name: employer.name,
                                                                        sic_code: employer.sic_code ) }

    let!(:prospect_plan_design_organization) { create(:plan_design_organization, sponsor_profile_id: nil,
                                                                    owner_profile_id: broker_agency_profile_id,
                                                                    legal_name: employer.name,
                                                                    sic_code: employer.sic_code ) }
    let(:user) { double(:user) }
    let(:datatable) { double(:datatable) }
    let(:sic_codes) { double(:sic_codes) }

    let(:valid_attributes) {
      {
        "legal_name"  =>  "Some Name",
        "dba"         =>  "",
        "entity_kind" =>  "",
        "sic_code"    =>  "0116",
        "office_locations_attributes" =>
              {"0"=>
                  { "address_attributes" =>
                      { "kind"      =>  "primary",
                        "address_1" =>  "",
                        "address_2" =>  "",
                        "city"      =>  "",
                        "state"     =>  "",
                        "zip"       =>  "01001",
                        "county"    =>  "Hampden"
                      },
                    "phone_attributes" =>
                      { "kind"      =>  "phone main",
                        "area_code" =>  "",
                        "number"    =>  "",
                        "extension" =>  ""
                      }
                  }
        }
      }
    }

    let(:invalid_attributes) {
      {
        "legal_name"  =>  nil,
        "sic_code"    =>  nil,
        "office_locations_attributes" =>
              {"0"=>
                  { "address_attributes" =>
                      { "kind"      =>  "primary",
                        "zip"       =>  "01001",
                        "county"    =>  "Hampden"
                      }
                  }
        }
      }
    }

    before do
      allow(subject).to receive(:current_person).and_return(current_person)
      allow(current_person).to receive(:broker_role).and_return(broker_role)
      allow(broker_role).to receive(:broker_agency_profile_id).and_return(broker_agency_profile.id)
      allow(subject).to receive(:active_user).and_return(active_user)
      allow(active_user).to receive(:has_hbx_staff_role?).and_return(false)
    end

    describe "GET #new" do
      USER_ROLES.each do |role|
        context "for user #{role}" do
          before do
            allow(subject).to receive(:init_organization).and_return(prospect_plan_design_organization)
            allow(active_user).to receive(:has_hbx_staff_role?).and_return( role == :with_hbx_staff_role ? true : false)
          end

          it "returns a success response" do
            get :new, { plan_design_organization_id: prospect_plan_design_organization.id }, valid_session
            expect(response).to be_success
          end
        end
      end
    end

    describe "GET #edit" do
      USER_ROLES.each do |role|
        context "for user #{role}" do
          before do
            allow(subject).to receive(:get_sic_codes).and_return(sic_codes)
            allow(active_user).to receive(:has_hbx_staff_role?).and_return( role == :with_hbx_staff_role ? true : false)
          end

          it "returns a success response" do
            get :edit, { id: prospect_plan_design_organization.to_param }, valid_session
            expect(response).to be_success
          end
        end
      end
    end

    describe "POST #create" do
      USER_ROLES.each do |role|
        context "for user #{role}" do
          before do
            allow(BrokerAgencyProfile).to receive(:find).with(broker_agency_profile.id).and_return(broker_agency_profile)
            allow(SponsoredBenefits::Organizations::BrokerAgencyProfile).to receive(:find_or_initialize_by).with(:fein).and_return("223232323")
            allow(active_user).to receive(:has_hbx_staff_role?).and_return( role == :with_hbx_staff_role ? true : false)
          end

          context "with valid params" do
            it "creates a new Organizations::PlanDesignOrganization" do
              expect {
                post :create, { organization: valid_attributes, broker_agency_id: broker_agency_profile.id, format: 'js'}, valid_session
              }.to change { Organizations::PlanDesignOrganization.all.count }.by(1)
            end

            it "redirects to employers_organizations_broker_agency_profile_path(broker_agency_profile)" do
              post :create, { organization: valid_attributes, broker_agency_id: broker_agency_profile.id, format: 'js'}, valid_session
              expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(broker_agency_profile))
            end
          end

          context "with invalid params" do
            before do
              allow(subject).to receive(:init_organization).and_return(prospect_plan_design_organization)
            end

            it "creates a new Organizations::PlanDesignOrganization" do
              expect {
                post :create, { organization: invalid_attributes, broker_agency_id: broker_agency_profile.id, format: 'js'}, valid_session
              }.to change { Organizations::PlanDesignOrganization.all.count }.by(0)
            end

            it "renders the new view" do
              post :create, { organization: invalid_attributes, broker_agency_id: broker_agency_profile.id, format: 'js'}, valid_session
              expect(response).to render_template(:new)
            end
          end
        end
      end
    end

    describe "PATCH #update" do
      USER_ROLES.each do |role|
        context "for user #{role}" do
          before do
            allow(BrokerAgencyProfile).to receive(:find).with(broker_agency_profile.id).and_return(broker_agency_profile)
            allow(SponsoredBenefits::Organizations::BrokerAgencyProfile).to receive(:find_or_initialize_by).with(:fein).and_return("223232323")
            allow(subject).to receive(:get_sic_codes).and_return(sic_codes)
            allow(active_user).to receive(:has_hbx_staff_role?).and_return( role == :with_hbx_staff_role ? true : false)
          end

          context "with valid params" do
            let(:updated_valid_attributes) {
              valid_attributes["legal_name"] = "Some New Name"
              valid_attributes
            }

            it "updates Organizations::PlanDesignOrganization" do
              expect {
                patch :update, { organization: updated_valid_attributes, id: prospect_plan_design_organization.id, format: 'js' }, valid_session
              }.to change { prospect_plan_design_organization.reload.legal_name }.to('Some New Name')
            end

            it "redirects to employers_organizations_broker_agency_profile_path(broker_agency_profile)" do
              patch :update, { organization: updated_valid_attributes, id: prospect_plan_design_organization.id, format: 'js' }, valid_session
              expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(broker_agency_profile))
            end

            it "does not create a new Organizations::PlanDesignOrganization" do
              expect {
                patch :update, { organization: valid_attributes, id: prospect_plan_design_organization.id, format: 'js'}, valid_session
              }.to change { Organizations::PlanDesignOrganization.all.count }.by(0)
            end
          end

          context "with invalid params" do
            it "does not update Organizations::PlanDesignOrganization" do
              expect {
                patch :update, { organization: invalid_attributes, id: prospect_plan_design_organization.id, format: 'js' }, valid_session
              }.not_to change { prospect_plan_design_organization.reload.legal_name }
            end

            it "renders edit with flash error" do
              patch :update, { organization: invalid_attributes, id: prospect_plan_design_organization.id, format: 'js' }, valid_session
              expect(response).to render_template(:edit)
            end
          end

          context "with params missing office_location_attributes" do
            let(:params_missing_ol_attrs) {
              valid_attributes.delete "office_locations_attributes"
              valid_attributes
            }

            it "does not update Organizations::PlanDesignOrganization" do
              expect {
                patch :update, { organization: params_missing_ol_attrs, id: prospect_plan_design_organization.id, format: 'js' }, valid_session
              }.not_to change { prospect_plan_design_organization.reload.legal_name }
            end

            it "redirects to employers_organizations_broker_agency_profile_path(broker_agency_profile) with flash error" do
              patch :update, { organization: params_missing_ol_attrs, id: prospect_plan_design_organization.id, format: 'js' }, valid_session
               expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(broker_agency_profile))
               expect(flash[:error]).to match(/Prospect Employer must have one Primary Office Location./)
            end
          end
        end
      end
    end

    describe "DELETE #destroy" do
      USER_ROLES.each do |role|
        context "for user #{role}" do
          let(:broker_agency_profile) { double(id: "12345") }

          before do
            allow(BrokerAgencyProfile).to receive(:find).with(broker_agency_profile.id).and_return(broker_agency_profile)
          end

          context "when attempting to delete plan design organizations without existing quotes" do
            let!(:prospect_plan_design_organization) { create(:plan_design_organization, sponsor_profile_id: nil, owner_profile_id: broker_agency_profile.id,
                                                                                legal_name: 'ABC Company', sic_code: '0197' ) }

            it "destroys the requested prospect_plan_design_organization" do
              expect {
                delete :destroy, {:id => prospect_plan_design_organization.to_param}, valid_session
              }.to change(SponsoredBenefits::Organizations::PlanDesignOrganization, :count).by(-1)
            end

            it "redirects to employers_organizations_broker_agency_profile_path(broker_agency_profile)" do
              delete :destroy, {:id => prospect_plan_design_organization.to_param}, valid_session
              expect(response).to redirect_to(employers_organizations_broker_agency_profile_path(broker_agency_profile))
            end
          end

          context "when attempting to delete plan design organizations with existing quotes" do
            let!(:prospect_plan_design_organization) { create(:plan_design_organization, sponsor_profile_id: '1', owner_profile_id: '12345',
                                                      plan_design_proposals: [ plan_design_proposal ], sic_code: '0197' ) }
            let(:plan_design_proposal) { build(:plan_design_proposal) }

            it "does not destroy the requested prospect_plan_design_organization" do
              expect {
                delete :destroy, {:id => prospect_plan_design_organization.to_param}, valid_session
              }.to change(SponsoredBenefits::Organizations::PlanDesignOrganization, :count).by(0)
            end

            it "redirects to employers_organizations_broker_agency_profile_path(broker_agency_profile)" do
              delete :destroy, {:id => prospect_plan_design_organization.to_param}, valid_session
              expect(response).to redirect_to(employers_organizations_broker_agency_profile_path(broker_agency_profile))
            end
          end

        end
      end
    end

  end
end
