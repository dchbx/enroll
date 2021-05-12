# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Insured::ConsumerRolesController, dbclean: :after_each, :type => :controller do
  let(:user){ FactoryBot.create(:user, :consumer) }

  context "When individual market is disabled" do
    before do
      allow(Settings.aca).to receive(:market_kinds).and_return(%w[shop])
      sign_in user
      get :search
    end

    it "redirects to root" do
      expect(response).to redirect_to(root_path)
    end
  end
end

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe Insured::ConsumerRolesController, dbclean: :after_each, :type => :controller do
    let(:user){ FactoryBot.create(:user, :consumer) }
    let(:person){ FactoryBot.build(:person) }
    let(:family){ double("Family") }
    let(:family_member){ double("FamilyMember") }
    let(:consumer_role){ FactoryBot.build(:consumer_role, :contact_method => "Paper Only") }
    let(:bookmark_url) {'localhost:3000'}

    before do
      allow_any_instance_of(ApplicationController).to receive(:individual_market_is_enabled?).and_return(true)
    end

    context "GET privacy",dbclean: :after_each do
      before(:each) do
        sign_in user
        allow(user).to receive(:person).and_return(person)
      end
      it "should redirect" do
        allow(person).to receive(:consumer_role?).and_return(true)
        allow(person).to receive(:consumer_role).and_return(consumer_role)
        allow(consumer_role).to receive(:bookmark_url).and_return("test")
        get :privacy, params: {:aqhp => 'true'}
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(person.consumer_role.bookmark_url)
      end
      it "should render privacy" do
        allow(person).to receive(:consumer_role?).and_return(false)
        get :privacy
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:privacy)
      end
    end

    describe "Get search",  dbclean: :after_each do
      let(:mock_employee_candidate) { instance_double("Forms::EmployeeCandidate", ssn: "333224444", dob: "08/15/1975") }

      before(:each) do
        sign_in user
        allow(Forms::EmployeeCandidate).to receive(:new).and_return(mock_employee_candidate)
        allow(user).to receive(:last_portal_visited=)
        allow(user).to receive(:save!).and_return(true)
        allow(user).to receive(:person).and_return(person)
        allow(person).to receive(:consumer_role).and_return(consumer_role)
        allow(person).to receive(:is_consumer_role_active?).and_return(false)
        allow(person).to receive(:is_resident_role_active?).and_return(false)
        allow(consumer_role).to receive(:save!).and_return(true)
      end

      it "should render search template" do
        get :search
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:search)
      end

      it "should set the session flag for aqhp the param exists" do
        get :search, params: { aqhp: true }
        expect(session[:individual_assistance_path]).to be_truthy
      end

      it "should unset the session flag for aqhp if the param does not exist upon return" do
        get :search, params: { aqhp: true }
        expect(session[:individual_assistance_path]).to be_truthy
        get :search, params: { uqhp: true }
        expect(session[:individual_assistance_path]).to be_falsey
      end

    end

    describe "POST match", dbclean: :after_each do
      let(:person_parameters) { { :first_name => "SOMDFINKETHING" } }
      let(:mock_consumer_candidate) { instance_double("Forms::ConsumerCandidate", :valid? => validation_result, ssn: "333224444", dob: Date.new(1975, 8, 15), :first_name => "fname", :last_name => "lname") }
      let(:mock_employee_candidate) { instance_double("Forms::EmployeeCandidate", :valid? => validation_result, ssn: "333224444", dob: Date.new(1975, 8, 15), :first_name => "fname", :last_name => "lname", :match_census_employees => []) }
      let(:mock_resident_candidate) { instance_double("Forms::ResidentCandidate", :valid? => validation_result, ssn: "", dob: Date.new(1975, 8, 15), :first_name => "fname", :last_name => "lname") }
      let(:found_person){ [] }
      let(:person){ instance_double("Person") }

      before(:each) do
        allow(user).to receive(:idp_verified?).and_return false
        sign_in(user)
        allow(mock_consumer_candidate).to receive(:match_person).and_return(found_person)
        allow(Forms::ConsumerCandidate).to receive(:new).with(person_parameters.merge({user_id: user.id})).and_return(mock_consumer_candidate)
        allow(Forms::EmployeeCandidate).to receive(:new).and_return(mock_employee_candidate)
        allow(Forms::ResidentCandidate).to receive(:new).and_return(mock_resident_candidate)
        allow(mock_employee_candidate).to receive(:valid?).and_return(false)
        allow(mock_resident_candidate).to receive(:valid?).and_return(false)
      end

      context "given invalid parameters", dbclean: :after_each do
        let(:validation_result) { false }
        let(:found_person) { [] }

        it "renders the 'search' template" do
          allow(mock_consumer_candidate).to receive(:errors).and_return({})
          post :match, params: { person: person_parameters }
          expect(response).to have_http_status(:success)
          expect(response).to render_template("search")
          expect(assigns[:consumer_candidate]).to eq mock_consumer_candidate
        end
      end

      context "given valid parameters", dbclean: :after_each do
        let(:validation_result) { true }

        context "but with no found employee", dbclean: :after_each do
          let(:found_person) { [] }
          let(:person){ double("Person") }
          let(:person_parameters){{"dob" => "1985-10-01", "first_name" => "martin","gender" => "male","last_name" => "york","middle_name" => "","name_sfx" => "","ssn" => "000000111"}}
          before :each do
            post :match, params: { :person => person_parameters }
          end

          it "renders the 'no_match' template", dbclean: :after_each do
            post :match, params: { person: person_parameters }
            expect(response).to have_http_status(:success)
            expect(response).to render_template("no_match")
            expect(assigns[:consumer_candidate]).to eq mock_consumer_candidate
          end

          context "that find a matching employee", dbclean: :after_each do
            let(:found_person) { [person] }

            it "renders the 'match' template" do
              post :match, params: { :person => person_parameters }
              expect(response).to have_http_status(:success)
              expect(response).to render_template("match")
              expect(assigns[:consumer_candidate]).to eq mock_consumer_candidate
            end
          end
        end

        context "when match employer with shop_market enabled", dbclean: :after_each do
          before :each do
            allow(mock_consumer_candidate).to receive(:valid?).and_return(true)
            allow(mock_employee_candidate).to receive(:valid?).and_return(true)
            allow(mock_employee_candidate).to receive(:match_census_employees).and_return([])
            #allow(mock_resident_candidate).to receive(:dob).and_return()
            allow(Factories::EmploymentRelationshipFactory).to receive(:build).and_return(true)
            EnrollRegistry[:aca_shop_market].feature.stub(:is_enabled).and_return(true)
            post :match, params: { :person => person_parameters }
          end

          it "render employee role match template" do
            expect(response).to have_http_status(:success)
            expect(response).to render_template('insured/employee_roles/match')
            expect(assigns[:employee_candidate]).to eq mock_employee_candidate
          end
        end

        context "when match employer with shop_market disabled", dbclean: :after_each do
          before :each do
            allow(mock_consumer_candidate).to receive(:valid?).and_return(true)
            allow(mock_employee_candidate).to receive(:valid?).and_return(true)
            allow(mock_employee_candidate).to receive(:match_census_employees).and_return([])
            #allow(mock_resident_candidate).to receive(:dob).and_return()
            allow(Factories::EmploymentRelationshipFactory).to receive(:build).and_return(true)
            EnrollRegistry[:aca_shop_market].feature.stub(:is_enabled).and_return(false)
            post :match, params: { :person => person_parameters }
          end

          it "render employee role match template" do
            expect(response).to have_http_status(:success)
            expect(response).not_to render_template('insured/employee_roles/match')
          end
        end
      end

      context "given user enters ssn that is already taken", dbclean: :after_each do
        let(:validation_result) { true }
        before(:each) do
          allow(mock_consumer_candidate).to receive(:valid?).and_return(false)
          allow(mock_consumer_candidate).to receive(:errors).and_return({:ssn_taken => "test test test"})
        end
        it "should navigate to another page which has information for user to signin/recover account" do
          post :match, params: { :person => person_parameters }
          expect(response).to redirect_to(ssn_taken_insured_consumer_role_index_path)
          expect(flash[:alert]).to match(/The SSN entered is associated with an existing user/i)
        end
      end
    end

    context "POST create", dbclean: :after_each do
      let(:person_params){{"dob" => "1985-10-01", "first_name" => "martin","gender" => "male","last_name" => "york","middle_name" => "","name_sfx" => "","ssn" => "000000111","user_id" => "xyz"}}
      let(:person_user){ double("User") }
      before(:each) do
        allow(Factories::EnrollmentFactory).to receive(:construct_employee_role).and_return(consumer_role)
        allow(consumer_role).to receive(:person).and_return(person)
        allow(person).to receive(:primary_family).and_return(family)
        allow(family).to receive(:create_dep_consumer_role)
        allow(person).to receive(:is_consumer_role_active?).and_return(true)
        allow(User).to receive(:find).and_return(person_user)
        allow(person_user).to receive(:person).and_return(person)

      end
      it "should create new person/consumer role object" do
        sign_in user
        post :create, params: { person: person_params }
        expect(response).to have_http_status(:redirect)
      end


    end


    context "POST create with failed construct_employee_role", dbclean: :after_each do
      let(:person_params) do
        {"dob" => SymmetricEncryption.encrypt("1985-10-01"),
         "first_name" => SymmetricEncryption.encrypt("martin"),
         "gender" => SymmetricEncryption.encrypt("male"),
         "last_name" => SymmetricEncryption.encrypt("york"),
         "middle_name" => SymmetricEncryption.encrypt(""),
         "ssn" => SymmetricEncryption.encrypt("000000111"),
         "user_id" => SymmetricEncryption.encrypt("xyz")}
      end
      let(:person_user){ double("User") }
      before(:each) do
        allow(Factories::EnrollmentFactory).to receive(:construct_consumer_role).and_return(nil)
        allow(User).to receive(:find).and_return(person_user)
        allow(Person).to receive(:find).and_return(person)
        allow(person_user).to receive(:person).and_return(person)
      end
      it "should throw a 500 error" do
        sign_in user
        post :create, params: { person: person_params }
        expect(response).to have_http_status(500)
      end
    end

    context "GET edit", dbclean: :after_each do
      before(:each) do
        allow(ConsumerRole).to receive(:find).and_return(consumer_role)
        allow(consumer_role).to receive(:person).and_return(person)
        allow(consumer_role).to receive(:build_nested_models_for_person).and_return(true)
        allow(user).to receive(:person).and_return(person)
        allow(person).to receive(:consumer_role).and_return(consumer_role)
        allow(consumer_role).to receive(:save!).and_return(true)
        allow(consumer_role).to receive(:bookmark_url=).and_return(true)
      end
      it "should render new template" do
        sign_in user
        get :edit, params: { id: "test" }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:edit)
      end
    end


    context "GET upload_ridp_document" do
      before(:each) do
        allow(user).to receive(:person).and_return(person)
        allow(person).to receive(:consumer_role?).and_return(true)
        allow(person).to receive(:consumer_role).and_return(consumer_role)
      end
      it "should render new template" do
        sign_in user
        get :upload_ridp_document
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:upload_ridp_document)
      end
    end

    context "PUT update" do
      let(:addresses_attributes) do
        {"0" => {"kind" => "home", "address_1" => "address1_a NE", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211", "id" => person.addresses[0].id.to_s},
         "1" => {"kind" => "mailing", "address_1" => "address1_b NE", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211", "id" => person.addresses[1].id.to_s} }
      end
      let(:consumer_role_attributes) {consumer_role.attributes.to_hash }
      let(:person_params) do
        {"family" => {"application_type" => "Phone"}, "dob" => "1985-10-01", "first_name" => "martin","gender" => "male","last_name" => "york","middle_name" => "","name_sfx" => "","ssn" => "468389102","user_id" => "xyz",
         us_citizen: "true", naturalized_citizen: "true"}
      end
      let(:person){ FactoryBot.create(:person, :with_family) }
      let(:census_employee){FactoryBot.build(:census_employee)}
      let(:employee_role){FactoryBot.build(:employee_role, :census_employee => census_employee)}


      before(:each) do
        allow(ConsumerRole).to receive(:find).and_return(consumer_role)
        allow(consumer_role).to receive(:build_nested_models_for_person).and_return(true)
        EnrollRegistry[:financial_assistance].feature.stub(:is_enabled).and_return(true)
        allow(consumer_role).to receive(:person).and_return(person)
        allow(user).to receive(:person).and_return person
        allow(person).to receive(:consumer_role).and_return consumer_role
        person_params[:addresses_attributes] = addresses_attributes
        person_params[:consumer_role_attributes] = consumer_role_attributes
        sign_in user
      end

      context "to verify new addreses not created on updating the existing address" do

        before :each do
          allow(controller).to receive(:update_vlp_documents).and_return(true)
          put :update, params: { person: person_params, id: "test" }
        end

        it "should not empty the person's addresses on update" do
          expect(person.addresses).not_to eq []
        end

        it "should update addresses" do
          expect(person.addresses.first.address_1).to eq addresses_attributes["0"]["address_1"]
          expect(person.addresses.last.address_2).to eq addresses_attributes["1"]["address_2"]
        end

        it "should have same number of addresses on update" do
          expect(person.addresses.count).to eq 2
        end
      end

      context 'Address attributes' do
        let(:valid_addresses_attributes) do
          {"0" => {"kind" => "home", "address_1" => "address1_a NE", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211"},
           "1" => {"kind" => "mailing", "address_1" => "address1_b NE", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211" } }
        end
        let(:invalid_addresses_attributes) do
          {"0" => {"kind" => "home", "address_1" => "address1_a NE", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "222"},
           "1" => {"kind" => "mailing", "address_1" => "test NE", "address_2" => "", "city" => "test", "state" => "DC", "zip" => "223"} }
        end

        it "should not update existing person with invalid addresses" do
          person_params[:addresses_attributes] = invalid_addresses_attributes
          allow(controller).to receive(:update_vlp_documents).and_return(true)
          put :update, params: { person: person_params, id: "test" }
          expect(response).to have_http_status(:success)
          expect(response).to render_template(:edit)
          expect(person.errors.full_messages).to include 'Home address: zip should be in the form: 12345 or 12345-1234'
        end

        it "should update existing person with valid addresses" do
          person_params[:phones_attributes] = valid_addresses_attributes
          allow(controller).to receive(:update_vlp_documents).and_return(true)
          put :update, params: { person: person_params, id: "test" }
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(ridp_agreement_insured_consumer_role_index_path)
        end
      end

      context "updates active employee roles if active employee roles are present for dual roles" do
        before :each do
          allow(controller).to receive(:update_vlp_documents).and_return(true)
          allow(person).to receive(:employee_roles).and_return [employee_role]
          EnrollRegistry[:aca_shop_market].feature.stub(:is_enabled).and_return(true)
          put :update, params: { person: person_params, id: "test" }
        end

        it "should update employee role contact method" do
          expect(person.consumer_role.contact_method).to eq(person.employee_roles.first.contact_method)
        end
      end


      it "should update existing person" do
        allow(consumer_role).to receive(:update_by_person).and_return(true)
        allow(controller).to receive(:update_vlp_documents).and_return(true)
        allow(controller).to receive(:is_new_paper_application?).and_return false
        put :update, params: { person: person_params, id: "test" }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(ridp_agreement_insured_consumer_role_index_path)
      end

      it "should redirect to help paying for coverage path when current user is admin & doing new paper app" do
        allow(controller).to receive(:update_vlp_documents).and_return(true)
        allow(controller).to receive(:is_new_paper_application?).and_return true
        put :update, params: {person: person_params, id: 'test'}
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to '/insured/consumer_role/help_paying_coverage'
      end

      it "should redirect to family members page when current user is admin & doing new paper app and faa is disabled" do
        EnrollRegistry[:financial_assistance].feature.stub(:is_enabled).and_return(false)
        allow(controller).to receive(:update_vlp_documents).and_return(true)
        allow(controller).to receive(:is_new_paper_application?).and_return true
        put :update, params: {person: person_params, id: 'test'}
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(insured_family_members_path(consumer_role_id: consumer_role.id))
      end

      it "should not update the person" do
        allow(controller).to receive(:update_vlp_documents).and_return(false)
        allow(consumer_role).to receive(:update_by_person).and_return(true)
        put :update, params: { person: person_params, id: "test" }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:edit)
      end

      it "should not update the person" do
        allow(controller).to receive(:update_vlp_documents).and_return(false)
        allow(consumer_role).to receive(:update_by_person).and_return(false)
        put :update, params: { person: person_params, id: "test" }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:edit)
      end

      it "should raise error" do
        put :update, params: { person: person_params, id: "test" }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:edit)
        expect(person.errors.full_messages).to include "Document type cannot be blank"
      end

      it "should call bubble_address_errors_by_person" do
        allow(controller).to receive(:update_vlp_documents).and_return(true)
        allow(consumer_role).to receive(:update_by_person).and_return(false)
        expect(controller).to receive(:bubble_address_errors_by_person)
        put :update, params: { person: person_params, id: "test" }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:edit)
      end
    end

    context "PUT update as HBX Admin" do

      let(:person_params) do
        {"family" => {"application_type" => "Curam"}, "dob" => "1985-10-01", "first_name" => "martin","gender" => "male","last_name" => "york","middle_name" => "","name_sfx" => "","ssn" => "468389102","user_id" => "xyz",
         us_citizen: "true", naturalized_citizen: "true"}
      end
      let(:person){ FactoryBot.create(:person, :with_family, :with_hbx_staff_role) }

      before(:each) do
        allow(ConsumerRole).to receive(:find).and_return(consumer_role)
        allow(consumer_role).to receive(:build_nested_models_for_person).and_return(true)
        EnrollRegistry[:financial_assistance].feature.stub(:is_enabled).and_return(true)
        allow(consumer_role).to receive(:person).and_return(person)
        allow(user).to receive(:person).and_return person
        allow(person).to receive(:consumer_role).and_return consumer_role
        sign_in user
      end

      it "should redirect to help paying for coverage path  when current user has application type as Curam" do
        allow(controller).to receive(:update_vlp_documents).and_return(true)
        allow(controller).to receive(:is_new_paper_application?).and_return false
        put :update, params: {person: person_params, id: "test"}
        expect(response).to have_http_status(:redirect)
        routes { FinancialAssistance::Engine.routes }
        expect(response).to redirect_to '/insured/consumer_role/help_paying_coverage'
      end

      it 'should update consumer identity and application fields to valid and redirect to help paying for coverage page when current user has application type as Curam' do
        person_params["family"]["application_type"] = "Curam"
        allow(controller).to receive(:update_vlp_documents).and_return(true)
        allow(controller).to receive(:is_new_paper_application?).and_return false
        put :update, params: {person: person_params, id: "test"}
        expect(consumer_role.identity_validation). to eq 'valid'
        expect(consumer_role.identity_validation). to eq 'valid'
        expect(consumer_role.identity_update_reason). to eq 'Verified from Curam'
        expect(response).to have_http_status(:redirect)
        routes { FinancialAssistance::Engine.routes }
        expect(response).to redirect_to '/insured/consumer_role/help_paying_coverage'
      end

      it "should update consumer identity and application fields to valid and redirect to family members page when current user has application type as Curam and faa is disabled" do
        EnrollRegistry[:financial_assistance].feature.stub(:is_enabled).and_return(false)
        person_params["family"]["application_type"] = "Curam"
        allow(controller).to receive(:update_vlp_documents).and_return(true)
        allow(controller).to receive(:is_new_paper_application?).and_return false
        put :update, params: {person: person_params, id: "test"}
        expect(consumer_role.identity_validation). to eq 'valid'
        expect(consumer_role.identity_validation). to eq 'valid'
        expect(consumer_role.identity_update_reason). to eq 'Verified from Curam'
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(insured_family_members_path(consumer_role_id: consumer_role.id))
      end

      it "should redirect to help paying for coverage page when current user has application type as Mobile" do
        person_params["family"]["application_type"] = "Mobile"
        allow(controller).to receive(:update_vlp_documents).and_return(true)
        allow(controller).to receive(:is_new_paper_application?).and_return false
        put :update, params: {person: person_params, id: "test"}
        expect(response).to have_http_status(:redirect)
        routes { FinancialAssistance::Engine.routes }
        expect(response).to redirect_to '/insured/consumer_role/help_paying_coverage'
      end

      it 'should update consumer identity and application fields to valid and redirect to help paying for coverage page when current user has application type as Mobile' do
        person_params["family"]["application_type"] = "Mobile"
        allow(controller).to receive(:update_vlp_documents).and_return(true)
        allow(controller).to receive(:is_new_paper_application?).and_return false
        put :update, params: {person: person_params, id: "test"}
        expect(consumer_role.identity_validation). to eq 'valid'
        expect(consumer_role.identity_validation). to eq 'valid'
        expect(consumer_role.identity_update_reason). to eq 'Verified from Mobile'
        expect(response).to have_http_status(:redirect)
        routes { FinancialAssistance::Engine.routes }
        expect(response).to redirect_to '/insured/consumer_role/help_paying_coverage'
      end
    end

    context "GET immigration_document_options" do
      let(:person) {FactoryBot.create(:person, :with_consumer_role)}
      let(:params) {{target_type: 'Person', target_id: "person_id", vlp_doc_target: "vlp doc", vlp_doc_subject: "I-327 (Reentry Permit)"}}
      let(:family_member) {FactoryBot.create(:person, :with_consumer_role)}
      before :each do
        sign_in user
      end

      context "target type is Person", dbclean: :after_each do
        before :each do
          allow(Person).to receive(:find).and_return person
          get :immigration_document_options, params: params, format: :js, xhr: true
        end
        it "should get person" do
          expect(response).to have_http_status(:success)
          expect(assigns(:target)).to eq person
        end

        it "assign vlp_doc_target from params" do
          expect(assigns(:vlp_doc_target)).to eq "vlp doc"
        end

        it "assign country of citizenship based on vlp document" do
          expect(assigns(:country)).to eq "Ukraine"
        end
      end

      context "target type is family member", dbclean: :after_each do
        xit "should get FamilyMember" do
          allow(Forms::FamilyMember).to receive(:find).and_return family_member
          get :immigration_document_options, params: {target_type: 'Forms::FamilyMember', target_id: "id", vlp_doc_target: "vlp doc"},  format: :js, xhr: true
          expect(response).to have_http_status(:success)
          expect(assigns(:target)).to eq family_member
          expect(assigns(:vlp_doc_target)).to eq "vlp doc"
        end
      end

      it "render javascript template" do
        allow(Person).to receive(:find).and_return person
        get :immigration_document_options, params: params, format: :js, xhr: true
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:immigration_document_options)
      end
    end

    context "GET ridp_agreement", dbclean: :after_each do
      let(:person100) { FactoryBot.create(:person, :with_family, :with_consumer_role) }

      context "with a user who has already passed RIDP", dbclean: :after_each do
        before :each do
          sign_in user
        end

        before :each do
          allow(user).to receive(:person).and_return(person100)
          allow(person100).to receive(:consumer_role?).and_return(true)
          allow(person100).to receive(:consumer_role).and_return(consumer_role)
          allow(person100).to receive(:completed_identity_verification?).and_return(true)
          allow(person100.consumer_role).to receive(:identity_verified?).and_return(true)
          allow(person100.consumer_role).to receive(:application_verified?).and_return(true)
          allow(person100.primary_family).to receive(:has_curam_or_mobile_application_type?).and_return(true)
          get "ridp_agreement"
        end

        it "should redirect" do
          expect(response).to be_redirect
        end
      end

      context "with a user who has not passed RIDP", dbclean: :after_each do
        before :each do
          sign_in user
        end

        before :each do
          allow(user).to receive(:person).and_return(person100)
          allow(person100).to receive(:completed_identity_verification?).and_return(false)
          allow(person100).to receive(:consumer_role).and_return(consumer_role)
          allow(person100.consumer_role).to receive(:identity_verified?).and_return(false)
          allow(person100.consumer_role).to receive(:application_verified?).and_return(false)
          allow(person100.primary_family).to receive(:has_curam_or_mobile_application_type?).and_return(false)
          get "ridp_agreement"
        end

        it "should render the agreement page" do
          expect(response).to render_template("ridp_agreement")
        end
      end
    end

    context "Post update application type" do
      let(:person) { FactoryBot.create(:person, :with_family, :with_consumer_role) }
      let(:consumer_params) {{"family" => {"application_type" => "Phone"}}}
      before :each do
        sign_in user
      end

      before :each do
        request.env["HTTP_REFERER"] = "http://test.com"
        allow(user).to receive(:person).and_return(person)
        allow(person).to receive(:consumer_role?).and_return(true)
        allow(person).to receive(:consumer_role).and_return(consumer_role)
      end

      it "should redirect back to the same page" do
        post :update_application_type, params: { consumer_role_id: person.consumer_role.id, :consumer_role => consumer_params }
        expect(response).to have_http_status(:redirect)
      end

    end

    describe "Post match resident role" do
      let(:person_parameters) { { :first_name => "SOMDFINKETHING" } }
      let(:resident_parameters) { { :first_name => "John", :last_name => "Smith1", :dob => "4/4/1972" }}
      let(:mock_consumer_candidate) { instance_double("Forms::ConsumerCandidate", :valid? => "true", ssn: "333224444", dob: Date.new(1968, 2, 3), :first_name => "fname", :last_name => "lname") }
      let(:mock_employee_candidate) { instance_double("Forms::EmployeeCandidate", :valid? => "true", ssn: "333224444", dob: Date.new(1975, 8, 15), :first_name => "fname", :last_name => "lname", :match_census_employees => []) }
      let(:mock_resident_candidate) { instance_double("Forms::ResidentCandidate", :valid? => "true", ssn: "", dob: Date.new(1975, 8, 15), :first_name => "fname", :last_name => "lname") }
      let(:found_person){ [] }
      let(:resident_role){ FactoryBot.build(:resident_role) }

      before(:each) do
        allow(user).to receive(:idp_verified?).and_return false
        sign_in(user)
        allow(mock_consumer_candidate).to receive(:match_person).and_return(person)
        allow(mock_resident_candidate).to receive(:match_person).and_return(person)
        allow(Forms::ConsumerCandidate).to receive(:new).with(resident_parameters.merge({user_id: user.id})).and_return(mock_consumer_candidate)
        allow(Forms::EmployeeCandidate).to receive(:new).and_return(mock_employee_candidate)
        allow(Forms::ResidentCandidate).to receive(:new).with(resident_parameters.merge({user_id: user.id})).and_return(mock_resident_candidate)
        allow(mock_employee_candidate).to receive(:valid?).and_return(false)
        allow(mock_resident_candidate).to receive(:valid?).and_return(true)
        allow(user).to receive(:person).and_return(person)
        allow(person).to receive(:is_consumer_role_active?).and_return(false)
        allow(person).to receive(:is_resident_role_active?).and_return(false)


      end

      context "with pre-existing consumer_role", dbclean: :after_each do
        it "should not have a resident role created for it" do
          post :match, params: {person: resident_parameters }
          expect(user.person.resident_role).to be_nil
          #expect(response).to redirect_to(family_account_path)
          expect(response).to render_template("match")
        end
      end

      context "with pre-existing resident_role", dbclean: :after_each do
        it "should navigate to family account page" do
          allow(person).to receive(:resident_role).and_return(resident_role)
          allow(person).to receive(:is_resident_role_active?).and_return(true)

          post :match, params: { person: resident_parameters }
          expect(user.person.resident_role).not_to be_nil
          expect(response).to redirect_to(family_account_path)
        end
      end

      context "with both resident and consumer roles", dbclean: :after_each do
        it "should navigate to family account page" do
          allow(person).to receive(:consumer_role).and_return(consumer_role)
          allow(person).to receive(:resident_role).and_return(resident_role)
          allow(person).to receive(:is_resident_role_active?).and_return(true)
          allow(person).to receive(:is_consumer_role_active?).and_return(true)

          post :match, params: { person: resident_parameters }
          expect(user.person.consumer_role).not_to be_nil
          expect(user.person.resident_role).not_to be_nil
          expect(response).to redirect_to(family_account_path)
        end
      end
    end

    describe "Get edit consumer role", dbclean: :after_each do
      let(:user) { FactoryBot.create(:user, :consumer, person: consumer_role.person) }
      let(:consumer_role) { FactoryBot.create(:consumer_role) }
      let(:other_consumer_role) { FactoryBot.create(:consumer_role, :bookmark_url => "http://localhost:3000/insured/consumer_role/591f44497af8800bb5000016/edit") }

      before(:each) do
        sign_in(user)
      end

      context "with bookmark_url pointing to another person's consumer role", dbclean: :after_each do

        it "should redirect to the edit page of the consumer role of the current user" do
          get :edit, params: { id: other_consumer_role.id.to_s }
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(edit_insured_consumer_role_path(user.person.consumer_role.id))
        end
      end

    end
  end
end
