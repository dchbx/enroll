require 'rails_helper'
module BenefitSponsors
  RSpec.describe Profiles::GeneralAgencies::GeneralAgencyProfilesController, type: :controller, dbclean: :after_each do

    before :all do
      DatabaseCleaner.clean
    end

    routes { BenefitSponsors::Engine.routes }
    let!(:user_with_hbx_staff_role) { FactoryBot.create(:user, :with_hbx_staff_role) }
    let!(:person) { FactoryBot.create(:person, user: user_with_hbx_staff_role )}
    let(:general_agency) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, :with_site) }
    let(:profile) { general_agency.profiles.first }

    context "#show" do
      context "when user signed in" do
        before do
          sign_in user_with_hbx_staff_role
          allow(controller).to receive(:set_flash_by_announcement).and_return(true)
          get :show, params: {id: profile.id}
        end

        it "should set general_agency_profile instance variable" do
          expect(assigns(:general_agency_profile)).to eq profile
        end

        it "should set provider as current person" do
          expect(assigns(:provider)).to eq person
        end

        it "should be success" do
          expect(response).to have_http_status(:success)
        end

        it "should render show template" do
          expect(response).to render_template(:show)
        end
      end

      context "when user not signed in" do
        before do
          get :show, params: {id: profile.id}
        end

        it "should redirect to the user's signup" do
          expect(response.location.include?('users/sign_up')).to be_truthy
        end
      end
    end

    context "#employers" do
      before do
        sign_in user_with_hbx_staff_role
        get :employers, params:{id: profile.id}, xhr: true
      end
      it "should set datatable instance variable" do
        expect(assigns(:datatable).class).to eq Effective::Datatables::BenefitSponsorsGeneralAgencyDataTable
      end

      it "should be success" do
        expect(response).to have_http_status(:success)
      end

      it "should render employers template" do
        expect(response).to render_template(:employers)
      end
    end

    # context "#staffs" do
    #   before do
    #     sign_in user_with_hbx_staff_role
    #     xhr :get, :staffs, id: profile.id
    #   end
    #   it "should set general_agency_profile instance variable" do
    #     expect(assigns(:general_agency_profile)).to eq profile
    #   end

    #   it "should be success" do
    #     expect(response).to have_http_status(:success)
    #   end

    #   it "should render staffs template" do
    #     expect(response).to render_template(:staffs)
    #   end
    # end

    context "#families" do
      before do
        sign_in user_with_hbx_staff_role
        get :families, params:{id: profile.id}, xhr: true
      end
      it "should set datatable instance variable" do
        expect(assigns(:datatable).class).to eq Effective::Datatables::BenefitSponsorsGeneralAgencyFamilyDataTable
      end

      it "should be success" do
        expect(response).to have_http_status(:success)
      end

      it "should render families template" do
        expect(response).to render_template(:families)
      end
    end
  end
end
