# frozen_string_literal: true

require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe Exchanges::ResidentsController, :type => :controller do
    let(:user){ FactoryBot.create(:user, :resident) }
    let(:person){ FactoryBot.create(:person) }
    let(:family){ double("Family") }
    let(:family_member){ double("FamilyMember") }
    let(:resident_role){ FactoryBot.build(:resident_role) }
    let(:bookmark_url) {'localhost:3000'}
    let(:permission) { FactoryBot.create(:permission, :hbx_staff) }
    let(:read_only_permission) { FactoryBot.create(:permission, :hbx_read_only) }
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_staff", permission_id: permission.id)}
    let(:hbx_read_only_role) { FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_staff", permission_id: read_only_permission.id)}

    describe "Get search" do
      let(:mock_resident_candidate) { instance_double("Forms::ResidentCandidate", dob: "12/26/1975") }

      before(:each) do
        allow(Forms::ResidentCandidate).to receive(:new).and_return(mock_resident_candidate)
        allow(user).to receive(:last_portal_visited=)
        allow(user).to receive(:save!).and_return(true)
        allow(user).to receive(:person).and_return(person)
        allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
        allow(person).to receive(:resident_role).and_return(resident_role)
        allow(person).to receive(:is_resident_role_active?).and_return(false)
        allow(resident_role).to receive(:save!).and_return(true)
        sign_in user
      end

      it "should render search template" do
        get :search
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:search)
      end
    end

    context "GET edit" do
      before(:each) do
        allow(ResidentRole).to receive(:find).and_return(resident_role)
        allow(resident_role).to receive(:person).and_return(person)
        allow(resident_role).to receive(:build_nested_models_for_person).and_return(true)
        allow(user).to receive(:person).and_return(person)
        allow(person).to receive(:resident_role).and_return(resident_role)
        allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
        allow(resident_role).to receive(:save!).and_return(true)
        allow(resident_role).to receive(:bookmark_url=).and_return(true)
      end
      it "should render edit template" do
        sign_in user
        get :edit, params: { id: "test" }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:edit)
      end
    end

    context "PUT update" do
      let(:invalid_phones_attributes) {{"0" => {"kind" => "home", "_destroy" => "false", "full_phone_number" => "(848) 484-84"}, "1" => {"kind" => "mobile", "_destroy" => "false", "full_phone_number" => ""}}}
      let(:valid_phones_attributes) {{"0" => {"kind" => "home", "_destroy" => "false", "full_phone_number" => "(848) 484-8499"}, "1" => {"kind" => "mobile", "_destroy" => "false", "full_phone_number" => ""}}}
      let(:person_params){{"dob" => "1985-10-01", "first_name" => "Nikola","gender" => "male","last_name" => "Rasevic","middle_name" => "Veljko", "is_incarcerated" => "false"}}
      before(:each) do
        allow(ResidentRole).to receive(:find).and_return(resident_role)
        allow(resident_role).to receive(:build_nested_models_for_person).and_return(true)
        allow(resident_role).to receive(:person).and_return(person)
        allow(user).to receive(:person).and_return person
        allow(person).to receive(:resident_role).and_return resident_role
        allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
        sign_in user
      end

      it "should not update existing person with invalid phone number" do
        person_params[:phones_attributes] = invalid_phones_attributes
        put :update, params: { person: person_params, id: "test" }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:edit)
        expect(person.errors.full_messages).to include "Home phone: Phone number must have 10 digits"
      end

      it "should update existing person with valid phone number" do
        person_params[:phones_attributes] = valid_phones_attributes
        put :update, params: { person: person_params, id: "test" }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(ridp_bypass_exchanges_residents_path)
      end

      context 'Address attributes' do
        let(:valid_addresses_attributes) do
          {"0" => {"kind" => "home", "address_1" => "address1_a", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211"},
           "1" => {"kind" => "mailing", "address_1" => "address1_b", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211" } }
        end
        let(:invalid_addresses_attributes) do
          {"0" => {"kind" => "home", "address_1" => "address1_a", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "222"},
           "1" => {"kind" => "mailing", "address_1" => "test", "address_2" => "", "city" => "test", "state" => "DC", "zip" => "223"} }
        end

        it "should not update existing person with invalid addresses" do
          person_params[:addresses_attributes] = invalid_addresses_attributes
          put :update, params: { person: person_params, id: "test" }
          expect(response).to have_http_status(:success)
          expect(response).to render_template(:edit)
          expect(person.errors.full_messages).to include 'Home address: zip should be in the form: 12345 or 12345-1234'
        end

        it "should update existing person with valid addresses" do
          person_params[:phones_attributes] = valid_addresses_attributes
          put :update, params: { person: person_params, id: "test" }
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(ridp_bypass_exchanges_residents_path)
        end
      end
    end

    context "Get begin_resident_enrollment" do
      before(:each) do
        allow(user).to receive(:person).and_return person
        allow(person).to receive(:hbx_staff_role).and_return hbx_staff_role
        sign_in user
      end

      it "should redirect to search_exchanges_residents_path template" do
        get :begin_resident_enrollment
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(search_exchanges_residents_path)
      end
    end

    context "Get resume_resident_enrollment" do
      before(:each) do
        allow(Person).to receive(:find).and_return(person)
        allow(person).to receive(:resident_role).and_return resident_role
        allow(person).to receive(:hbx_staff_role).and_return hbx_staff_role
        allow(user).to receive(:person).and_return person
        sign_in user
      end

      it "should redirect to search_exchanges_residents_path template" do
        get :resume_resident_enrollment
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(family_account_path)
      end
    end

    context "Get begin_resident_enrollment without proper permission" do
      before(:each) do
        allow(user).to receive(:person).and_return person
        allow(person).to receive(:hbx_staff_role).and_return hbx_read_only_role
        sign_in user
      end

      it "should redirect to search_exchanges_residents_path template" do
        get :begin_resident_enrollment
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(destroy_user_session_path)
      end
    end
  end
end
