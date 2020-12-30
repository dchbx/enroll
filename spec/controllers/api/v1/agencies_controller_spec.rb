require 'rails_helper'

RSpec.describe Api::V1::AgenciesController, :type => :controller, :dbclean => :after_each do
  let(:user) { FactoryBot.create(:user) }

  describe "when unauthorized" do
    before :each do
      sign_in(user)
    end

    it "forbids access to GET #index" do
      get :index
      expect(response.status).to eq(403)
    end

    it "forbids access to GET #primary_agency_staff" do
      get :primary_agency_staff
      expect(response.status).to eq(403)
    end

    it "forbids access to GET #agency_staff" do
      get :agency_staff
      expect(response.status).to eq(403)
    end

    it "forbids access to GET #agency_staff_detail" do
      get :agency_staff_detail, params: { person_id: "1234" }
      expect(response.status).to eq(403)
    end

    it "forbids access to POST #terminate" do
      post :terminate, params: { person_id: "1234", role_id: "5678" }
      expect(response.status).to eq(403)
    end

  end

  describe "when authorized" do

    let(:policy) do
      instance_double(
        AngularAdminApplicationPolicy
      )
    end

    describe "GET #index, with no records" do
      before :each do
        sign_in(user)
        allow(AngularAdminApplicationPolicy).to receive(:new) do |u, resource|
          expect(u).to eq user
          expect(resource.class).to eq Queries::AgenciesQuery
          policy
        end
        allow(policy).to receive(:list_agencies?).and_return(true)
        get :index
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "has and empty json response" do
        expect(response.body).to eq("[]")
      end
    end

    describe "GET #index, with a broker agency" do
      let(:broker_agency) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }

      before :each do
        broker_agency
        sign_in(user)
        allow(AngularAdminApplicationPolicy).to receive(:new) do |u, resource|
          expect(u).to eq user
          expect(resource.class).to eq Queries::AgenciesQuery
          policy
        end
        allow(policy).to receive(:list_agencies?).and_return(true)
        get :index
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "has and empty json response" do
        expect(response.body).not_to eq("[]")
      end
    end

    describe "GET #index, with a general agency" do
      let(:org) { FactoryBot.build(:benefit_sponsors_organizations_exempt_organization) }
      let(:general_agency) { FactoryBot.create(:benefit_sponsors_organizations_general_agency_profile, organization: org) }

      before :each do
        general_agency
        sign_in(user)
        allow(AngularAdminApplicationPolicy).to receive(:new) do |u, resource|
          expect(u).to eq user
          expect(resource.class).to eq Queries::AgenciesQuery
          policy
        end
        allow(policy).to receive(:list_agencies?).and_return(true)
        get :index
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "has and empty json response" do
        expect(response.body).not_to eq("[]")
      end
    end

    describe "GET #primary_agency_staff, with no records" do
      before :each do
        sign_in(user)
        allow(AngularAdminApplicationPolicy).to receive(:new) do |u, resource|
          expect(u).to eq user
          expect(resource.class).to eq Queries::People::PrimaryAgentsQuery
          policy
        end
        allow(policy).to receive(:list_primary_agency_staff?).and_return(true)
        get :primary_agency_staff
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "has and empty json response" do
        expect(response.body).to eq("[]")
      end
    end

    describe "GET #primary_agency_staff, with a broker" do
      let(:broker_role) { FactoryBot.create(:broker_role, aasm_state: "active") }

      before :each do
        broker_role
        sign_in(user)
        allow(AngularAdminApplicationPolicy).to receive(:new) do |u, resource|
          expect(u).to eq user
          expect(resource.class).to eq Queries::People::PrimaryAgentsQuery
          policy
        end
        allow(policy).to receive(:list_primary_agency_staff?).and_return(true)
        get :primary_agency_staff
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "has no records" do
        expect(response.body).not_to eq("[]")
      end
    end

    describe "GET #primary_agency_staff, with a ga staff" do
      let(:general_staff_role) {FactoryBot.create(:general_agency_staff_role, aasm_state: "active", is_primary: true)}
      before :each do
        general_staff_role
        sign_in(user)
        allow(AngularAdminApplicationPolicy).to receive(:new) do |u, resource|
          expect(u).to eq user
          expect(resource.class).to eq Queries::People::PrimaryAgentsQuery
          policy
        end
        allow(policy).to receive(:list_primary_agency_staff?).and_return(true)
        get :primary_agency_staff
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "has no records" do
        expect(response.body).not_to eq("[]")
      end
    end

    describe "GET #agency_staff, with no records" do
      before :each do
        sign_in(user)
        allow(AngularAdminApplicationPolicy).to receive(:new) do |u, resource|
          expect(u).to eq user
          expect(resource.class).to eq Queries::People::NonPrimaryAgentsQuery
          policy
        end
        allow(policy).to receive(:list_agency_staff?).and_return(true)
        get :agency_staff
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "has and empty json response" do
        expect(response.body).to eq("[]")
      end
    end

    describe "GET #agency_staff, with a broker_agency_staff" do
      let(:broker_agency) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }
      let(:broker_role) { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency.id) }

      before :each do
        broker_role
        sign_in(user)
        allow(AngularAdminApplicationPolicy).to receive(:new) do |u, resource|
          expect(u).to eq user
          expect(resource.class).to eq Queries::People::NonPrimaryAgentsQuery
          policy
        end
        allow(policy).to receive(:list_agency_staff?).and_return(true)
        get :agency_staff
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "has no records" do
        expect(response.body).not_to eq("[]")
      end
    end

    describe "GET #agency_staff, with a ga staff" do
      let(:general_staff_role) {FactoryBot.create(:general_agency_staff_role, aasm_state: "active", is_primary: false)}
      before :each do
        general_staff_role
        sign_in(user)
        allow(AngularAdminApplicationPolicy).to receive(:new) do |u, resource|
          expect(u).to eq user
          expect(resource.class).to eq Queries::People::NonPrimaryAgentsQuery
          policy
        end
        allow(policy).to receive(:list_agency_staff?).and_return(true)
        get :agency_staff
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "has no records" do
        expect(response.body).not_to eq("[]")
      end
    end

    describe "POST #terminate with an active role" do
      before :each do
        sign_in(user)
        allow(AngularAdminApplicationPolicy).to receive(:new) do |u, resource|
          expect(u).to eq user
          expect(resource.class).to eq Operations::TerminateAgencyStaff
          policy
        end
        allow(policy).to receive(:terminate_agency_staff?).and_return(true)
      end

      context "has a valid role to terminate" do
        let(:person) { FactoryBot.create(:person, broker_agency_staff_roles: broker_agency_staff_role) }
        let(:broker_agency) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }
        let(:broker_agency_staff_role) {[FactoryBot.create(
          :broker_agency_staff_role,
          aasm_state: "active",
          benefit_sponsors_broker_agency_profile_id: broker_agency.id
          )]}

        it "is successful the first time" do
          post :terminate, params: { person_id: person.id.to_s, role_id: broker_agency_staff_role.first.id.to_s }
          expect(response.status).to eq(200)
        end
      end

      context "with a person that doesn't exist" do
        it "returns not found" do
          post :terminate, params: { person_id: "aksdfuidfa", role_id: "blargh" }
          expect(response.status).to eq(400)
        end
      end

      context "has a role that can't be terminated" do
        let(:person) { FactoryBot.create(:person, broker_agency_staff_roles: broker_agency_staff_role) }
        let(:broker_agency) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }
        let(:broker_agency_staff_role) {[FactoryBot.create(
          :broker_agency_staff_role,
          aasm_state: "broker_agency_terminate",
          benefit_sponsors_broker_agency_profile_id: broker_agency.id
          )]}

        it "fails to transition" do
          post :terminate, params: { person_id: person.id.to_s, role_id: broker_agency_staff_role.first.id.to_s }
          expect(response.status).to eq(500)
        end
      end
    end

    describe "PATCH #update_person" do
      let(:person) { FactoryBot.create(:person, first_name: 'test', last_name: 'test', dob: TimeKeeper.date_of_record - 25.years) }

      context 'valid case' do

        before :each do
          sign_in(user)
          allow(AngularAdminApplicationPolicy).to receive(:new) do |u, resource|
            expect(u).to eq user
            expect(resource.class).to eq Operations::UpdateStaff
            policy
          end
          allow(policy).to receive(:update_staff?).and_return(true)
          patch :update_person, params: {person_id: person.id, first_name: 'test updated', last_name: 'test', dob: (TimeKeeper.date_of_record - 35.years).strftime('%F')}
          person.reload
        end

        it "is successful" do
          expect(response.status).to eq(200)
        end

        it "should update person first name" do
          expect(person.first_name).to eq 'test updated'
        end

        it "should update person dob" do
          expect(person.dob).to eq TimeKeeper.date_of_record - 35.years
        end
      end

      context 'invalid case' do
        let!(:duplicate_person) { FactoryBot.create(:person, first_name: 'test updated', last_name: 'test', dob: TimeKeeper.date_of_record - 35.years) }

        before :each do
          sign_in(user)
          allow(AngularAdminApplicationPolicy).to receive(:new) do |u, resource|
            expect(u).to eq user
            expect(resource.class).to eq Operations::UpdateStaff
            policy
          end
          allow(policy).to receive(:update_staff?).and_return(true)
          patch :update_person, params: {person_id: person.id, first_name: 'test updated', last_name: 'test', dob: (TimeKeeper.date_of_record - 35.years).strftime('%F')}
          person.reload
        end

        it "is successful" do
          expect(response.status).to eq(409)
        end

        it "should not update person first name" do
          expect(person.first_name).not_to eq 'test updated'
        end

        it "should not update person dob" do
          expect(person.dob).not_to eq TimeKeeper.date_of_record - 35.years
        end
      end
    end

    describe "PATCH #update_email" do
      let(:person) { FactoryBot.create(:person, emails: [work_email]) }
      let(:work_email) { FactoryBot.build(:email, kind: 'work', address: 'test@test.com')}
      before :each do
        sign_in(user)
        allow(AngularAdminApplicationPolicy).to receive(:new) do |u, resource|
          expect(u).to eq user
          expect(resource.class).to eq Operations::UpdateStaff
          policy
        end
        allow(policy).to receive(:update_staff?).and_return(true)
        patch :update_email, params: {person_id: person.id, emails: [id: work_email.id, address: 'testupdated@test.com']}
        person.reload
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "should update person's work email'" do
        expect(person.emails.first.address).to eq 'testupdated@test.com'
      end
    end
  end
end
