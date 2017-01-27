require 'rails_helper'

RSpec.describe SamlController do

  describe "POST login" do
    let(:user) { FactoryGirl.create(:user, last_portal_visited: family_account_path)}

    invalid_xml = File.read("spec/saml/invalid_saml_response.xml")

    context "with devise session active" do
      it "should sign out current user" do
        sign_in user
        expect(subject).to receive(:sign_out).with(user)
        post :login, :SAMLResponse => invalid_xml
      end
    end

    context "with invalid saml response" do

      it "should render a 403" do
        expect(subject).to receive(:log) do |arg1, arg2|
          expect(arg1).to match(/ERROR: SAMLResponse assertion errors/)
          expect(arg2).to eq(:severity => 'error')
        end

        post :login, :SAMLResponse => invalid_xml
        expect(response).to render_template(:file => "#{Rails.root}/public/403.html")
        expect(response).to have_http_status(403)
      end
    end

    context "with valid saml response" do
      sample_xml = File.read("spec/saml/invalid_saml_response.xml")
      let(:name_id) { user.oim_id }
      let(:valid_saml_response) { double(is_valid?: true, :"settings=" => true, attributes: attributes_double, name_id: name_id)}
      let(:attributes_double) { { 'mail' => user.email} }

      before do
        allow(OneLogin::RubySaml::Response).to receive(:new).with(sample_xml, :allowed_clock_drift => 5.seconds).and_return( valid_saml_response )
      end

      describe "with an existing user" do
        let!(:person) {FactoryGirl.create(:person, user: user)}

        it "should redirect back to their last portal" do
          expect(::IdpAccountManager).to receive(:update_navigation_flag).with(name_id, attributes_double['mail'], ::IdpAccountManager::ENROLL_NAVIGATION_FLAG)
          post :login, :SAMLResponse => sample_xml
          expect(response).to redirect_to(user.last_portal_visited)
          expect(flash[:notice]).to eq "Signed in Successfully."
          expect(User.where(email: user.email).first.oim_id).to eq name_id
          expect(User.where(email: user.email).first.idp_verified).to be_truthy
        end

        context "with relay state" do
          let(:relay_state_url) { "/employers/employer_profiles/new" }

          it "should redirect back to their the relay state" do
            expect(::IdpAccountManager).to receive(:update_navigation_flag).with(name_id, attributes_double['mail'], ::IdpAccountManager::ENROLL_NAVIGATION_FLAG)
            post :login, :SAMLResponse => sample_xml, :RelayState => relay_state_url
            expect(response).to redirect_to(relay_state_url)
            expect(flash[:notice]).to eq "Signed in Successfully."
            expect(User.where(email: user.email).first.oim_id).to eq name_id
            expect(User.where(email: user.email).first.idp_verified).to be_truthy
          end
        end
      end

      describe "with a new user", dbclean: :after_each do
        let(:name_id) { attributes_double['mail'] }
        let(:attributes_double) { { 'mail' => "new@user.com"} }

        it "should claim the invitation" do
          expect(::IdpAccountManager).to receive(:update_navigation_flag).with(name_id, attributes_double['mail'], ::IdpAccountManager::ENROLL_NAVIGATION_FLAG)
          post :login, :SAMLResponse => sample_xml
          expect(response).to redirect_to(search_insured_consumer_role_index_path)
          expect(flash[:notice]).to eq "Signed in Successfully."
          expect(User.where(email: attributes_double['mail']).first.oim_id).to eq name_id
          expect(User.where(email: attributes_double['mail']).first.idp_verified).to be_truthy
        end

        context "who has a headless user with same email but different username" do
          let!(:email_matched_user) { FactoryGirl.create(:user, email: attributes_double['mail'])}

          it "should claim the invitation" do
            expect(::IdpAccountManager).to receive(:update_navigation_flag).with(name_id, attributes_double['mail'], ::IdpAccountManager::ENROLL_NAVIGATION_FLAG)
            post :login, :SAMLResponse => sample_xml
            expect(response).to redirect_to(search_insured_consumer_role_index_path)
            expect(flash[:notice]).to eq "Signed in Successfully."
            expect(User.where(email: attributes_double['mail']).first.oim_id).to eq name_id
            expect(User.where(email: attributes_double['mail']).first.idp_verified).to be_truthy
          end
        end

        context "with no email attribute passed" do
          let(:name_id) { "someuser"}
          let(:attributes_double) { { } }

          it "should claim the invitation" do
            expect(::IdpAccountManager).to receive(:update_navigation_flag).with(name_id, attributes_double['mail'], ::IdpAccountManager::ENROLL_NAVIGATION_FLAG)
            post :login, :SAMLResponse => sample_xml
            expect(response).to redirect_to(search_insured_consumer_role_index_path)
            expect(flash[:notice]).to eq "Signed in Successfully."
            expect(User.where(oim_id: name_id).first.oim_id).to eq name_id
            expect(User.where(oim_id: name_id).first.idp_verified).to be_truthy
          end

          context "with a user that already has an empty e-mail" do
            let(:name_id) { "someotheruser"}
            let(:attributes_double) { { } }

            it "should claim the invitation" do
              expect(::IdpAccountManager).to receive(:update_navigation_flag).with(name_id, attributes_double['mail'], ::IdpAccountManager::ENROLL_NAVIGATION_FLAG)
              post :login, :SAMLResponse => sample_xml
              expect(response).to redirect_to(search_insured_consumer_role_index_path)
              expect(flash[:notice]).to eq "Signed in Successfully."
              expect(User.where(oim_id: name_id).first.oim_id).to eq name_id
              expect(User.where(oim_id: name_id).first.idp_verified).to be_truthy
            end
          end
        end

        context "with relay state" do
          let(:attributes_double) { { 'mail' => "another_new@user.com"} }
          let(:relay_state_url) { "/insured/employee/search" }

          it "should redirect back to the relay state url" do
            expect(::IdpAccountManager).to receive(:update_navigation_flag).with(name_id, attributes_double['mail'], ::IdpAccountManager::ENROLL_NAVIGATION_FLAG)
            post :login, :SAMLResponse => sample_xml, :RelayState => relay_state_url
            expect(response).to redirect_to(relay_state_url)
            expect(flash[:notice]).to eq "Signed in Successfully."
            expect(User.where(email: attributes_double['mail']).first.oim_id).to eq name_id
            expect(User.where(email: attributes_double['mail']).first.idp_verified).to be_truthy
          end
        end
      end

      context "with no name id attribute" do
         let(:name_id) { nil }

        it "should render a 403 and log the error as critical" do
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to match(/ERROR: SAMLResponse has missing required mail attribute/)
            expect(arg2).to eq(:severity => 'critical')
          end

          post :login, :SAMLResponse => sample_xml
          expect(response).to render_template(:file => "#{Rails.root}/public/403.html")
          expect(response).to have_http_status(403)
        end
      end
    end
  end

  describe "GET navigate_to_assistance" do

    context "logged on user" do
      let(:user) { FactoryGirl.create(:user, last_portal_visited: family_account_path, oim_id: 'some_curam_id')}

      it "should redirect user to curam URL" do
        sign_in user
        allow(::IdpAccountManager).to receive(:update_navigation_flag).with(user.oim_id, user.email, ::IdpAccountManager::CURAM_NAVIGATION_FLAG)
        get :navigate_to_assistance
        expect(response).to redirect_to(SamlInformation.curam_landing_page_url)
      end
    end

    context "user not logged on" do
      it "should redirect user to login URL" do
        allow(controller).to receive(:current_user).and_return(false)
        get :navigate_to_assistance
        expect(response).to redirect_to(SamlInformation.iam_login_url)
      end
    end
  end

end
