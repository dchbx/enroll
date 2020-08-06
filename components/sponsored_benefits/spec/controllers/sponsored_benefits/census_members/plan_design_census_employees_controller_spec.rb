# frozen_string_literal: true

require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"


module SponsoredBenefits
  RSpec.describe CensusMembers::PlanDesignCensusEmployeesController, type: :controller, dbclean: :after_each do
    include_context "set up broker agency profile for BQT, by using configuration settings"

    routes { SponsoredBenefits::Engine.routes }

    let(:valid_attributes) do
      {
        "first_name" => "John",
        "middle_name" => "",
        "last_name" => "Chan",
        "dob" => "12/01/1975",
        "name_sfx" => "",
        "ssn" => "",
        "benefit_sponsorship_id" => benefit_sponsorship.id,
        "address_attributes" => {
          "kind" => "home", "address_1" => "", "address_2" => "", "city" => "", "state" => "", "zip" => ""
        },
        "email_attributes" => {
          "kind" => "", "address" => ""
        },
        "census_dependents_attributes" => {
          "0" => {"first_name" => "David", "middle_name" => "", "last_name" => "Chan", "dob" => "2002-12-01", "employee_relationship" => "child_under_26", "_destroy" => "false", "ssn" => ""},
          "1" => {"first_name" => "Lara", "middle_name" => "", "last_name" => "Chan", "dob" => "1979-12-01", "employee_relationship" => "spouse", "_destroy" => "false", "ssn" => ""}
        }
      }
    end

    describe "GET index" do
      let(:person) do
        FactoryBot.create(:person, :with_broker_role).tap do |person|
          person.broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id.to_s)
        end
      end

      let!(:user_with_broker_role) { FactoryBot.create(:user, person: person) }

      it "returns a success response" do
        sign_in user_with_broker_role
        get :index, params: { plan_design_proposal_id: plan_design_proposal.id }
        expect(response).to be_successful
      end
    end

    describe "GET show" do
      let(:person) do
        FactoryBot.create(:person, :with_broker_role).tap do |person|
          person.broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id.to_s)
        end
      end

      let!(:user_with_broker_role) { FactoryBot.create(:user, person: person) }

      it "returns a success response" do
        sign_in user_with_broker_role
        get :show, params: {plan_design_proposal_id: plan_design_proposal.id, :id => plan_design_census_employee.to_param}
        expect(response).to be_successful
      end
    end

    describe "GET new" do
      let(:person) do
        FactoryBot.create(:person, :with_broker_role).tap do |person|
          person.broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id.to_s)
        end
      end

      let!(:user_with_broker_role) { FactoryBot.create(:user, person: person) }

      it "returns a success response" do
        sign_in user_with_broker_role
        get :new, xhr: true, params: {plan_design_proposal_id: plan_design_proposal.id}
        expect(assigns(:census_employee)).to be_a(SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee)
        expect(response).to be_successful
        expect(response).to render_template('new')
      end

      context "upload" do
        it "returns a success response" do
          sign_in user_with_broker_role
          get :new, xhr: true, params: { plan_design_proposal_id: plan_design_proposal.id, modal: "upload"}
          expect(assigns(:census_employee)).to be_a(SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee)
          expect(response).to be_successful
          expect(response).to render_template('upload_employees')
        end
      end
    end

    describe "GET #edit" do
      let(:person) do
        FactoryBot.create(:person, :with_broker_role).tap do |person|
          person.broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id.to_s)
        end
      end

      let!(:user_with_broker_role) { FactoryBot.create(:user, person: person) }

      it "returns a success response" do
        sign_in user_with_broker_role
        get :edit, xhr: true, params: {plan_design_proposal_id: plan_design_proposal.id, :id => plan_design_census_employee.to_param}
        expect(assigns(:census_employee)).to eq plan_design_census_employee
        expect(response).to be_successful
        expect(response).to render_template('edit')
      end
    end

    describe "POST #create" do

      let(:person) do
        FactoryBot.create(:person, :with_broker_role).tap do |person|
          person.broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id.to_s)
        end
      end

      let!(:user_with_broker_role) { FactoryBot.create(:user, person: person) }

      context "with valid params" do
        let(:plan_proposal) { plan_design_proposal }
        let(:plan_design_org) {plan_proposal.plan_design_organization}

        before :each do
          request.env["HTTP_REFERER"] = "http://test.host"
        end

        it "creates a new CensusMembers::PlanDesignCensusEmployee" do
          sign_in user_with_broker_role
          post :create, params: {plan_design_proposal_id: plan_design_proposal.id, census_members_plan_design_census_employee: valid_attributes}
          expect(response).to redirect_to "http://test.host"
        end

        it "creates a new CensusMembers::PlanDesignCensusEmployee with dependents" do
          sign_in user_with_broker_role
          post :create, params: {plan_design_proposal_id: plan_design_proposal.id, census_members_plan_design_census_employee: valid_attributes}
          census_employee = CensusMembers::PlanDesignCensusEmployee.last
          expect(census_employee.census_dependents.size).to eq 2
          spouse = census_employee.census_dependents.detect {|cd| cd.employee_relationship == 'spouse'}
          child = census_employee.census_dependents.detect {|cd| cd.employee_relationship == 'child_under_26'}
          expect(spouse.present?).to be_truthy
          expect(spouse.first_name).to eq "Lara"
          expect(child.present?).to be_truthy
          expect(child.first_name).to eq "David"
          expect(census_employee.address).to be_nil
          expect(census_employee.email).to be_nil
        end

        it "redirects to proposal edit page" do
          edit_url = edit_organizations_plan_design_organization_plan_design_proposal_path(plan_design_org, plan_proposal)
          request.env["HTTP_REFERER"] = edit_url
          sign_in user_with_broker_role
          post :create, params: {plan_design_proposal_id: plan_design_proposal.id, census_members_plan_design_census_employee: valid_attributes}
          expect(flash[:success]).to eq "Employee record created successfully."
          expect(response).to redirect_to edit_url
        end
      end

      context "with invalid params" do

        before :each do
          request.env["HTTP_REFERER"] = "http://test.host"
        end

        it "returns a success response (i.e. to display the 'new' template)" do
          sign_in user_with_broker_role
          valid_attributes["dob"] = nil
          post :create, params: {plan_design_proposal_id: plan_design_proposal.id, census_members_plan_design_census_employee: valid_attributes}
          expect(flash[:error]).to eq "Unable to create employee record. [\"Dob can't be blank\", \"Dob can't be blank\"]"

          expect(response).to redirect_to "http://test.host"
        end
      end
    end

    describe "DELETE #destroy" do
      let(:person) do
        FactoryBot.create(:person, :with_broker_role).tap do |person|
          person.broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id.to_s)
        end
      end

      let!(:user_with_broker_role) { FactoryBot.create(:user, person: person) }

      it "destroys the requested census_members_plan_design_census_employee" do
        sign_in user_with_broker_role
        plan_design_census_employee = CensusMembers::PlanDesignCensusEmployee.create! valid_attributes
        expect do
          delete :destroy, params: {plan_design_proposal_id: plan_design_proposal.id.to_s, id: plan_design_census_employee.id.to_s, format: :js}
        end.to change(CensusMembers::PlanDesignCensusEmployee, :count).by(-1)
      end

      it "redirects to the census_members_plan_design_census_employees list" do
        sign_in user_with_broker_role
        plan_design_census_employee = CensusMembers::PlanDesignCensusEmployee.create! valid_attributes
        delete :destroy, params: { plan_design_proposal_id: plan_design_proposal.id.to_s, id: plan_design_census_employee.id.to_s, format: :js}
        expect(response.code).to eq "200"
      end
    end

    describe "PUT #update" do
      let(:person) do
        FactoryBot.create(:person, :with_broker_role).tap do |person|
          person.broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id.to_s)
        end
      end

      let!(:user_with_broker_role) {FactoryBot.create(:user, person: person)}
      let(:new_attributes) do
        {
          "first_name" => "John",
          "middle_name" => "",
          "last_name" => "Chan",
          "dob" => "12/01/1975",
          "name_sfx" => "",
          "ssn" => ""
        }
      end
      let(:address_attributes) {{ "kind" => "home", "address_1" => "", "address_2" => "", "city" => "", "state" => "", "zip" => "" }}
      let(:email_attributes) {{ "kind" => "", "address" => "" }}
      let(:census_dependents_attributes) do
        {
          "0" => {"first_name" => "David", "middle_name" => "", "last_name" => "Chan", "dob" => "2002-12-01", "employee_relationship" => "child_under_26", "_destroy" => "false", "ssn" => ""},
          "1" => {"first_name" => "Lara", "middle_name" => "", "last_name" => "Chan", "dob" => "1979-12-01", "employee_relationship" => "spouse", "_destroy" => "false", "ssn" => ""}
        }
      end
      let(:praposal) {plan_design_proposal}
      let(:benefit_sponsor) {benefit_sponsorship}

      let!(:census_employee) { CensusMembers::PlanDesignCensusEmployee.create(new_attributes.merge(benefit_sponsorship: benefit_sponsor)) }

      before :each do
        sign_in user_with_broker_role
      end

      context "with valid params" do

        context "when dependent added" do
          it "should add dependents" do
            expect(census_employee.census_dependents).to be_empty
            put :update, xhr: true, params: {plan_design_proposal_id: praposal.id.to_s, :id => census_employee.id.to_s, :census_members_plan_design_census_employee => new_attributes.merge(census_dependents_attributes: census_dependents_attributes)}
            census_employee.reload
            expect(census_employee.census_dependents.size).to eq 2
            expect(response).to be_successful
            expect(response).to render_template('update')
          end
        end

        context "when dependent deleted" do
          let(:census_employee) {CensusMembers::PlanDesignCensusEmployee.create(new_attributes.merge(census_dependents_attributes: census_dependents_attributes, benefit_sponsorship: benefit_sponsor))}
          let(:spouse) {census_employee.census_dependents.detect {|cd| cd.employee_relationship == 'spouse'}}
          let(:child) {census_employee.census_dependents.detect {|cd| cd.employee_relationship == 'child_under_26'}}
          let(:delete_dependents_attributes) do
            {
              "0" => {"id" => spouse.id.to_s, "first_name" => "Lara", "middle_name" => "", "last_name" => "Chan", "dob" => "1979-12-01", "employee_relationship" => "spouse", "ssn" => "", "_destroy" => "false"},
              "1" => {"id" => child.id.to_s}
            }
          end

          it "should drop dependents" do
            expect(census_employee.census_dependents.size).to eq 2
            put :update, xhr: true, params: {plan_design_proposal_id: plan_design_proposal.id, :id => census_employee.to_param, :census_members_plan_design_census_employee => new_attributes.merge(census_dependents_attributes: delete_dependents_attributes)}
            census_employee.reload
            expect(census_employee.census_dependents.size).to eq 1
            expect(census_employee.census_dependents.detect {|cd| cd.employee_relationship == 'child_under_26'}).to be_nil
          end
        end

        context "update employee or dependent information" do
          let(:census_employee) {CensusMembers::PlanDesignCensusEmployee.create(new_attributes.merge(census_dependents_attributes: census_dependents_attributes, benefit_sponsorship: benefit_sponsor))}
          let(:spouse) {census_employee.census_dependents.detect {|cd| cd.employee_relationship == 'spouse'}}
          let(:child) {census_employee.census_dependents.detect {|cd| cd.employee_relationship == 'child_under_26'}}

          let(:updated_attributes) do
            {
              "first_name" => "John",
              "middle_name" => "",
              "last_name" => "Chan",
              "dob" => "12/01/1978",
              "name_sfx" => "",
              "ssn" => "512141210",
              "address_attributes" => {"kind" => "home", "address_1" => "100 Bakers street", "address_2" => "", "city" => "Boston", "state" => "MA", "zip" => "01118"},
              "email_attributes" => {"kind" => "home", "address" => "john.chan@gmail.com"},
              "census_dependents_attributes" => {
                "0" => {"id" => child.id.to_s, "first_name" => "David", "middle_name" => "Li", "last_name" => "Chan", "dob" => "2002-12-01", "employee_relationship" => "child_under_26", "_destroy" => "false", "ssn" => ""},
                "1" => {"id" => spouse.id.to_s, "first_name" => "Lara", "middle_name" => "", "last_name" => "Chan", "dob" => "1980-12-01", "employee_relationship" => "spouse", "_destroy" => "false", "ssn" => ""}
              }
            }
          end

          it "should update employee and dependents information" do
            put :update, xhr: true, params: {plan_design_proposal_id: praposal.id, :id => census_employee.to_param, :census_members_plan_design_census_employee => updated_attributes}
            census_employee.reload
            expect((census_employee.email.attributes.to_a & updated_attributes["email_attributes"].to_a).to_h).to eq updated_attributes["email_attributes"]
            expect((census_employee.address.attributes.to_a & updated_attributes["address_attributes"].to_a).to_h).to eq updated_attributes["address_attributes"]
            expect(census_employee.ssn).to eq updated_attributes["ssn"]
            expect(census_employee.census_dependents.detect {|cd| cd.employee_relationship == 'spouse'}.dob.strftime("%Y-%m-%d")).to eq "1980-12-01"
            expect(census_employee.census_dependents.detect {|cd| cd.employee_relationship == 'child_under_26'}.middle_name).to eq "Li"
          end
        end
      end
    end
  end
end
