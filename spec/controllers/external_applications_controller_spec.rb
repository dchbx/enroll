require "rails_helper"

RSpec.describe ExternalApplicationsController, :type => :controller, :dbclean => :after_each do

  let(:user) { FactoryBot.create(:user) }
  
  describe "GET show" do

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in(user)
    end

    describe "for a non-existent application" do
      before :each do
        allow(ExternalApplications::ApplicationProfile).to receive(:find_by_application_name).with("klsjadfjklaer").and_return(nil)
      end

      it "displays a 404" do
        get :show, params: {id: "klsjadfjklaer"}
        expect(response.status).to eq 404
        expect(response.body).to be_empty
      end
    end

    describe "for an existing, unauthorized application" do
      let(:mock_external_application) do
        instance_double(
          ExternalApplications::ApplicationProfile,
          {
            :policy_class => AngularAdminApplicationPolicy
          }
        )
      end

      let(:mock_policy) do
        instance_double(
          AngularAdminApplicationPolicy
        )
      end

      before :each do
        allow(AngularAdminApplicationPolicy).to receive(
          :new
        ).with(user, mock_external_application).and_return(mock_policy)
        allow(ExternalApplications::ApplicationProfile).to receive(
          :find_by_application_name
        ).with("admin").and_return(mock_external_application)
        allow(mock_policy).to receive(:visit?).and_return(false)
      end

      it "redirects" do
        get :show, params: {id: "admin"}
        expect(response.status).to eq 302
      end
    end

    describe "for an existing, authorized application" do
      let(:mock_external_application) do
        instance_double(
          ExternalApplications::ApplicationProfile,
          {
            :policy_class => AngularAdminApplicationPolicy,
            :url => "some_url_path",
            :name => "admin"
          }
        )
      end

      let(:mock_policy) do
        instance_double(
          AngularAdminApplicationPolicy
        )
      end

      before :each do
        allow(AngularAdminApplicationPolicy).to receive(
          :new
        ).with(user, mock_external_application).and_return(mock_policy)
        allow(ExternalApplications::ApplicationProfile).to receive(
          :find_by_application_name
        ).with("admin").and_return(mock_external_application)
        allow(mock_policy).to receive(:visit?).and_return(true)
      end

      it "is a success" do
        get :show, params: {id: "admin"}
        expect(response.status).to eq 200
      end

      it "renders the show page" do
        get :show, params: {id: "admin"}
        expect(response.status).to eq 200
      end

      it "sets the jwt and url" do
        get :show, params: {id: "admin"}
        expect(assigns[:jwt]).not_to be nil
        expect(assigns[:url]).to eq "some_url_path"
      end
    end
  end
end