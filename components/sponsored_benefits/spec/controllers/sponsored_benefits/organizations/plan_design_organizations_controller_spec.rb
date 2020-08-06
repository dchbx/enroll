# frozen_string_literal: true

require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module UserRoles
  USER_ROLES = [:with_hbx_staff_role, :with_broker_role].freeze unless const_defined?(:USER_ROLES)
end

module SponsoredBenefits
  include UserRoles

  RSpec.describe Organizations::PlanDesignOrganizationsController, type: :controller, dbclean: :around_each  do
    include_context "set up broker agency profile for BQT, by using configuration settings"

    routes { SponsoredBenefits::Engine.routes }

    let(:valid_attributes) do
      {
        "legal_name" => "Some Name",
        "dba" => "",
        "entity_kind" => "",
        "sic_code" => "0116",
        "office_locations_attributes" =>
              {"0" =>
                  { "address_attributes" =>
                      { "kind" => "primary",
                        "address_1" => "",
                        "address_2" => "",
                        "city" => "",
                        "state" => "",
                        "zip" => "01001",
                        "county" => "Hampden"},
                    "phone_attributes" =>
                      { "kind" => "work",
                        "area_code" => "",
                        "number" => "",
                        "extension" => ""}}}
      }
    end

    let(:invalid_attributes) do
      {
        "legal_name" => "",
        "sic_code" => nil,
        "office_locations_attributes" =>
              {"0" =>
                  { "address_attributes" =>
                      { "kind" => "primary",
                        "zip" => "01001",
                        "county" => "Hampden"}}}
      }
    end

    def person(trait)
      FactoryBot.create(:person, trait).tap do |person|
        person.broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id.to_s) if trait == :with_broker_role
      end
    end

    def user(person)
      FactoryBot.create(:user, person: person)
    end


    describe "GET new" do
      USER_ROLES.each do |role|

        before :each do
          person = person(role)
          sign_in user(person)
          get :new, params: {broker_agency_id: broker_agency_profile.id.to_s}
        end

        it "should assign organization  with user role as #{role}" do
          expect(assigns(:organization).class).to eq SponsoredBenefits::Forms::PlanDesignOrganizationSignup
        end

        it "should returns a success response" do
          expect(response).to be_successful
        end
      end
    end

    describe "POST create" do
      USER_ROLES.each do |role|
        context "for user with role #{role} by passing valid params" do
          let(:broker_profile) { broker_agency_profile }

          before :each do
            person = person(role)
            sign_in user(person)
            post :create, params: {organization: valid_attributes, broker_agency_id: broker_profile.id, format: 'js'}
          end


          it "creates a new Organizations::PlanDesignOrganization" do
            expect(SponsoredBenefits::Organizations::PlanDesignOrganization.where(legal_name: valid_attributes["legal_name"]).present?).to be_truthy
          end

          it "redirects to employers_organizations_broker_agency_profile_path(broker_agency_profile)" do
            expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(broker_profile))
          end
        end
      end

      USER_ROLES.each do |role|
        context "for user with role #{role} by passing invalid params" do
          before :each do
            person = person(role)
            sign_in user(person)
            post :create, params: {organization: invalid_attributes, broker_agency_id: broker_agency_profile.id, format: 'js'}
          end

          it " should not create a new Organizations::PlanDesignOrganization" do
            expect(SponsoredBenefits::Organizations::PlanDesignOrganization.where(legal_name: invalid_attributes["legal_name"]).present?).to be_falsy
          end

          it "renders the new view" do
            expect(response).to render_template(:new)
          end
        end
      end
    end

    describe "GET edit" do
      USER_ROLES.each do |role|
        before :each do
          person = person(role)
          sign_in user(person)
          get :edit, params: {id: prospect_plan_design_organization.id}
        end
        context "for user #{role}" do

          it "returns a success response" do
            expect(response).to be_successful
          end
        end
      end
    end

    describe "PATCH update" do
      let(:prospect_organization) {prospect_plan_design_organization}
      let(:updated_params) {valid_attributes.merge({legal_name: "TOYOTA"})}

      USER_ROLES.each do |role|
        context "for user #{role} with with valid params" do

          before :each do
            person = person(role)
            sign_in user(person)
            patch :update, params: {organization: updated_params, id: prospect_organization.id.to_s, profile_id: prospect_organization.broker_agency_profile}
          end

          it "should update plan design organization legal_name" do
            expect(prospect_organization.reload.legal_name).to eq updated_params[:legal_name]
          end

          it "should re-direct to employers page" do
            broker_profile = prospect_organization.reload.broker_agency_profile
            expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(broker_profile))
          end
        end

        context "for user #{role}" do
          let(:with_out_office_params) { {legal_name: "TESLA"}}
          before :each do
            person = person(role)
            sign_in user(person)
            patch :update, params: {organization: with_out_office_params, id: prospect_organization.id.to_s, profile_id: prospect_organization.broker_agency_profile}
          end

          it "should not update legal_name and throw flash error" do
            expect(prospect_plan_design_organization.legal_name).not_to eq "TESLA"
            expect(flash[:error]).to match(/Prospect Employer must have one Primary Office Location./)
            expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(prospect_organization.broker_agency_profile))
          end
        end

        context "for user #{role} by passing not a prospect employer" do
          let(:organization) {plan_design_organization}
          before :each do
            person = person(role)
            sign_in user(person)
            patch :update, params: {id: organization.id.to_s, profile_id: organization.broker_agency_profile}
          end

          it "should throw a flash Error" do
            expect(flash[:error]).to match(/Updating of Client employer records not allowed/)
            expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(organization.broker_agency_profile))
          end
        end
      end
    end

    describe "DELETE destroy" do
      USER_ROLES.each do |role|
        context "for user #{role} when organization is not prospect" do
          let(:organization) {plan_design_organization}

          before :each do
            person = person(role)
            sign_in user(person)
            delete :destroy, params: {id: organization.id.to_s}
          end

          it "should throw a flash Error and should re-direct" do
            expect(flash[:error]).to match(/Removing of Client employer records not allowed/)
            expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(organization.broker_agency_profile))
            expect(response).to have_http_status(303)
          end
        end

        context "for user #{role} when organization is prospect" do
          let(:plan_proposal) {plan_design_proposal}
          let(:plan_design_org_with_praposals) {plan_proposal.plan_design_organization}

          before :each do
            person = person(role)
            sign_in user(person)
          end

          context "when quotes are present" do
            it "should not delete proposals" do
              expect(plan_proposal.valid?).to be_truthy
              delete :destroy, params: {id: plan_design_org_with_praposals.id.to_s}
              expect(plan_design_org_with_praposals.plan_design_proposals.present?).to be_truthy
            end

            it "should re-direct and throw a flash error" do
              delete :destroy, params: {id: plan_design_org_with_praposals.id.to_s}
              expect(response).to have_http_status(303)
              expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(plan_design_org_with_praposals.broker_agency_profile))
            end
          end
        end
      end
    end
  end
end
