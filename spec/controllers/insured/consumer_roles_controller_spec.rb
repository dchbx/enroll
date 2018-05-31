require 'rails_helper'
RSpec.describe Insured::ConsumerRolesController, :type => :controller do
  let(:user){ FactoryGirl.create(:user, :consumer) }

  context "When individual market is disabled" do
    before do
      Settings.aca.market_kinds = %W[shop]
      sign_in user
      get :search
    end

    it "redirects to root" do
      expect(response).to redirect_to(root_path)
    end
  end
end

RSpec.describe Insured::ConsumerRolesController, :type => :controller do
  let(:user){ FactoryGirl.create(:user, :consumer) }
  let(:person){ FactoryGirl.build(:person) }
  let(:family){ double("Family") }
  let(:family_member){ double("FamilyMember") }
  let(:consumer_role){ FactoryGirl.build(:consumer_role) }
  let(:bookmark_url) {'localhost:3000'}

  before do
    allow_any_instance_of(ApplicationController).to receive(:individual_market_is_enabled?).and_return(true)
  end

  context "GET privacy" do
    before(:each) do
      sign_in user
      allow(user).to receive(:person).and_return(person)
    end
    it "should redirect" do
      allow(person).to receive(:consumer_role?).and_return(true)
      allow(person).to receive(:consumer_role).and_return(consumer_role)
      allow(consumer_role).to receive(:bookmark_url).and_return("test")
      get :privacy, {:aqhp => 'true'}
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(person.consumer_role.bookmark_url+"?aqhp=true")
    end
    it "should render privacy" do
      allow(person).to receive(:consumer_role?).and_return(false)
      get :privacy
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:privacy)
    end
  end

  describe "Get search" do
    let(:mock_employee_candidate) { instance_double("Forms::EmployeeCandidate", ssn: "333224444", dob: "08/15/1975") }

    before(:each) do
      sign_in user
      allow(Forms::EmployeeCandidate).to receive(:new).and_return(mock_employee_candidate)
      allow(user).to receive(:last_portal_visited=)
      allow(user).to receive(:save!).and_return(true)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:consumer_role).and_return(consumer_role)
      allow(person).to receive(:has_active_consumer_role?).and_return(false)
      allow(consumer_role).to receive(:save!).and_return(true)
    end

    it "should render search template" do
      get :search
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:search)
    end

    it "should set the session flag for aqhp the param exists" do
      get :search, aqhp: true
      expect(session[:individual_assistance_path]).to be_truthy
    end

    it "should unset the session flag for aqhp if the param does not exist upon return" do
      get :search, aqhp: true
      expect(session[:individual_assistance_path]).to be_truthy
      get :search, uqhp: true
      expect(session[:individual_assistance_path]).to be_falsey
    end

  end

  describe "POST match" do
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

    context "given invalid parameters" do
      let(:validation_result) { false }
      let(:found_person) { [] }

      it "renders the 'search' template" do
        allow(mock_consumer_candidate).to receive(:errors).and_return({})
        post :match, :person => person_parameters
        expect(response).to have_http_status(:success)
        expect(response).to render_template("search")
        expect(assigns[:consumer_candidate]).to eq mock_consumer_candidate
      end
    end

    context "given valid parameters" do
      let(:validation_result) { true }

      context "but with no found employee" do
        let(:found_person) { [] }
        let(:person){ double("Person") }
        let(:person_parameters){{"dob"=>"1985-10-01", "first_name"=>"martin","gender"=>"male","last_name"=>"york","middle_name"=>"","name_sfx"=>"","ssn"=>"000000111"}}
        before :each do
          post :match, :person => person_parameters
        end

        it "renders the 'no_match' template" do
          post :match, :person => person_parameters
          expect(response).to have_http_status(:success)
          expect(response).to render_template("no_match")
          expect(assigns[:consumer_candidate]).to eq mock_consumer_candidate
        end

        context "that find a matching employee" do
          let(:found_person) { [person] }

          it "renders the 'match' template" do
            post :match, :person => person_parameters
            expect(response).to have_http_status(:success)
            expect(response).to render_template("match")
            expect(assigns[:consumer_candidate]).to eq mock_consumer_candidate
          end
        end
      end

      context "when match employer" do
        before :each do
          allow(mock_consumer_candidate).to receive(:valid?).and_return(true)
          allow(mock_employee_candidate).to receive(:valid?).and_return(true)
          allow(mock_employee_candidate).to receive(:match_census_employees).and_return([])
          #allow(mock_resident_candidate).to receive(:dob).and_return()
          allow(Factories::EmploymentRelationshipFactory).to receive(:build).and_return(true)
          post :match, :person => person_parameters
        end

        it "render employee role match template" do
          expect(response).to have_http_status(:success)
          expect(response).to render_template('insured/employee_roles/match')
          expect(assigns[:employee_candidate]).to eq mock_employee_candidate
        end
      end
    end

    context "given user enters ssn that is already taken" do
      let(:validation_result) { true }
      before(:each) do
        allow(mock_consumer_candidate).to receive(:valid?).and_return(false)
        allow(mock_consumer_candidate).to receive(:errors).and_return({:ssn_taken => "test test test"})
      end
      it "should navigate to another page which has information for user to signin/recover account" do
        post :match, :person => person_parameters
        expect(response).to redirect_to(ssn_taken_insured_consumer_role_index_path)
        expect(flash[:alert]).to eq "The SSN entered is associated with an existing user. Please <a href=\"https://iam_login_url\">Sign In</a> with your user name and password or <a href=\"https://account_recovery\">Click here</a> if you've forgotten your password."
      end
    end
  end

  context "POST create" do
    let(:person_params){{"dob"=>"1985-10-01", "first_name"=>"martin","gender"=>"male","last_name"=>"york","middle_name"=>"","name_sfx"=>"","ssn"=>"000000111","user_id"=>"xyz"}}
    before(:each) do
      allow(Factories::EnrollmentFactory).to receive(:construct_employee_role).and_return(consumer_role)
      allow(consumer_role).to receive(:person).and_return(person)
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:create_dep_consumer_role)
    end
    it "should create new person/consumer role object" do
      sign_in user
      post :create, person: person_params
      expect(response).to have_http_status(:redirect)
    end


  end


  context "POST create with failed construct_employee_role" do
    let(:person_params){{"dob"=>"1985-10-01", "first_name"=>"martin","gender"=>"male","last_name"=>"york","middle_name"=>"","name_sfx"=>"","ssn"=>"000000111","user_id"=>"xyz"}}
    before(:each) do
      allow(Factories::EnrollmentFactory).to receive(:construct_consumer_role).and_return(nil)
    end
    it "should throw a 500 error" do
      sign_in user
      post :create, person: person_params
      expect(response).to have_http_status(500)
    end
  end

  context "GET edit" do
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
      get :edit, id: "test"
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
    end
  end

  context "PUT update" do
    let(:person_params){{"dob"=>"1985-10-01", "first_name"=>"martin","gender"=>"male","last_name"=>"york","middle_name"=>"","name_sfx"=>"","ssn"=>"468389102","user_id"=>"xyz", us_citizen:"true", naturalized_citizen: "true"}}
    let(:person){ FactoryGirl.create(:person) }

    before(:each) do
      allow(ConsumerRole).to receive(:find).and_return(consumer_role)
      allow(consumer_role).to receive(:build_nested_models_for_person).and_return(true)
      allow(consumer_role).to receive(:person).and_return(person)
      allow(user).to receive(:person).and_return person
      allow(person).to receive(:consumer_role).and_return consumer_role
      sign_in user
    end


    context "to verify new addreses not created on updating the existing address" do
      before :each do
        put :update, person: person_params, id: "test"
      end

      it "should not empty the person's addresses on update" do
        expect(person.addresses).not_to eq []
      end

      it "should not create new address instances on update" do
        expect(person.addresses.map(&:id).map(&:to_s)).to eq person.addresses.map(&:id).map(&:to_s)
      end

      it "should have same number of addresses on update" do
        expect(person.addresses.count).to eq 2
      end
    end

    it "should update existing person" do
      allow(consumer_role).to receive(:update_by_person).and_return(true)
      allow(controller).to receive(:update_vlp_documents).and_return(true)
      allow(controller).to receive(:is_new_paper_application?).and_return false
      put :update, person: person_params, id: "test"
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(ridp_agreement_insured_consumer_role_index_path)
    end

    it "should redirect to family members path when current user is admin & doing new paper app" do
      allow(controller).to receive(:update_vlp_documents).and_return(true)
      allow(controller).to receive(:is_new_paper_application?).and_return true
      put :update, person: person_params, id: "test"
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(insured_family_members_path(consumer_role_id: consumer_role.id))
    end

    it "should not update the person" do
      allow(controller).to receive(:update_vlp_documents).and_return(false)
      allow(consumer_role).to receive(:update_by_person).and_return(true)
      put :update, person: person_params, id: "test"
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
    end

    it "should not update the person" do
      allow(controller).to receive(:update_vlp_documents).and_return(false)
      allow(consumer_role).to receive(:update_by_person).and_return(false)
      put :update, person: person_params, id: "test"
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
    end

    it "should raise error" do
      put :update, person: person_params, id: "test"
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
      expect(person.errors.full_messages).to include "Document type cannot be blank"
    end

    it "should call bubble_address_errors_by_person" do
      allow(controller).to receive(:update_vlp_documents).and_return(true)
      allow(consumer_role).to receive(:update_by_person).and_return(false)
      expect(controller).to receive(:bubble_address_errors_by_person)
      put :update, person: person_params, id: "test"
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
    end
  end

  context "GET immigration_document_options" do
    let(:person) {FactoryGirl.create(:person, :with_consumer_role)}
    let(:params) {{target_type: 'Person', target_id: "person_id", vlp_doc_target: "vlp doc", vlp_doc_subject: "I-327 (Reentry Permit)"}}
    let(:family_member) {FactoryGirl.create(:person, :with_consumer_role)}
    before :each do
      sign_in user
    end

    context "target type is Person" do
      before :each do
        allow(Person).to receive(:find).and_return person
        xhr :get, 'immigration_document_options', params, format: :js
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

    context "target type is family member" do
      xit "should get FamilyMember" do
        allow(Forms::FamilyMember).to receive(:find).and_return family_member
        xhr :get, 'immigration_document_options', {target_type: 'Forms::FamilyMember', target_id: "id", vlp_doc_target: "vlp doc", format: :js}
        expect(response).to have_http_status(:success)
        expect(assigns(:target)).to eq family_member
        expect(assigns(:vlp_doc_target)).to eq "vlp doc"
      end
    end

    it "render javascript template" do
      allow(Person).to receive(:find).and_return person
      xhr :get, 'immigration_document_options', params, format: :js
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:immigration_document_options)
    end
  end

  context "GET ridp_agreement" do

    context "with a user who has already passed RIDP" do
      before :each do
        sign_in user
      end

      before :each do
        allow(user).to receive(:person).and_return(person)
        allow(person).to receive(:consumer_role?).and_return(true)
        allow(person).to receive(:consumer_role).and_return(consumer_role)
        allow(person).to receive(:completed_identity_verification?).and_return(true)
        get "ridp_agreement"
      end

      it "should redirect" do
        expect(response).to be_redirect
      end
    end

    context "with a user who has not passed RIDP" do
      before :each do
        sign_in user
      end

      before :each do
        allow(user).to receive(:person).and_return(person)
        allow(person).to receive(:completed_identity_verification?).and_return(false)
        get "ridp_agreement"
      end

      it "should render the agreement page" do
        expect(response).to render_template("ridp_agreement")
      end
    end
  end

  describe "Post match resident role" do
    let(:person_parameters) { { :first_name => "SOMDFINKETHING" } }
    let(:resident_parameters) { { :first_name => "John", :last_name => "Smith1", :dob => "4/4/1972" }}
    let(:mock_consumer_candidate) { instance_double("Forms::ConsumerCandidate", :valid? => "true", ssn: "333224444", dob: Date.new(1968, 2, 3), :first_name => "fname", :last_name => "lname") }
    let(:mock_employee_candidate) { instance_double("Forms::EmployeeCandidate", :valid? => "true", ssn: "333224444", dob: Date.new(1975, 8, 15), :first_name => "fname", :last_name => "lname", :match_census_employees => []) }
    let(:mock_resident_candidate) { instance_double("Forms::ResidentCandidate", :valid? => "true", ssn: "", dob: Date.new(1975, 8, 15), :first_name => "fname", :last_name => "lname") }
    let(:found_person){ [] }
    let(:resident_role){ FactoryGirl.build(:resident_role) }

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
    end

    context "with pre-existing consumer_role" do
      it "should not have a resident role created for it" do
        post :match, :person => resident_parameters
        expect(user.person.resident_role).to be_nil
        #expect(response).to redirect_to(family_account_path)
        expect(response).to render_template("match")
      end
    end

    context "with pre-existing resident_role" do
      it "should navigate to family account page" do
        allow(person).to receive(:resident_role).and_return(resident_role)
        post :match, :person => resident_parameters
        expect(user.person.resident_role).not_to be_nil
        expect(response).to redirect_to(family_account_path)
      end
    end

    context "with both resident and consumer roles" do
      it "should navigate to family account page" do
        allow(person).to receive(:consumer_role).and_return(consumer_role)
        allow(person).to receive(:resident_role).and_return(resident_role)
        post :match, :person => resident_parameters
        expect(user.person.consumer_role).not_to be_nil
        expect(user.person.resident_role).not_to be_nil
        expect(response).to redirect_to(family_account_path)
      end
    end
  end

  describe "Get edit consumer role" do
    let(:consumer_role2){ FactoryGirl.build(:consumer_role, :bookmark_url => "http://localhost:3000/insured/consumer_role/591f44497af8800bb5000016/edit") }
    before(:each) do
      current_user = user
      allow(ConsumerRole).to receive(:find).and_return(consumer_role)
      allow(consumer_role).to receive(:person).and_return(person)
      allow(consumer_role).to receive(:build_nested_models_for_person).and_return(true)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:consumer_role).and_return(consumer_role2)
      allow(consumer_role).to receive(:save!).and_return(true)
      allow(consumer_role).to receive(:bookmark_url=).and_return(true)
      allow(user).to receive(:has_consumer_role?).and_return(true)

    end

    context "with bookmark_url pointing to another person's consumer role" do

      it "should redirect to the edit page of the consumer role of the current user" do
        sign_in user
        get :edit, id: "test"
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(edit_insured_consumer_role_path(user.person.consumer_role.id))
      end
    end

  end
end
