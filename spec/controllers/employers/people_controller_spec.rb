require 'rails_helper'

RSpec.describe Employers::PeopleController do
  describe "GET search" do
    let(:user) { double("user") }
    let(:person) { double("person")}

    it "renders the 'search' template" do
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:agent?).and_return(false)
      sign_in(user)
      get :search
      expect(response).to have_http_status(:success)
      expect(response).to render_template("search")
      expect(assigns(:person).class).to eq (Forms::EmployeeCandidate)
    end
  end

  describe "POST create" do
    let(:user) { double("user") }
    let(:person_parameters) { { :first_name => "SOMDFINKETHING" } }
    let(:phones) {double(:select => double("select")) }
    let(:addresses) {double(:select => double("select")) }
    let(:emails) {double(:select => double("select")) }
    let(:person) { double(:phones => phones, :addresses => addresses, :emails => emails)}

    before(:each) do
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:agent?).and_return(false)
      sign_in(user)
      post :create, params: {person: person_parameters}
    end

    context "it should create person when create person button is clicked" do
      let(:validation_result) { true }

      it "should call edit method" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("edit")
      end
    end
  end

  describe "POST match" do
    let(:user) { double(id: user_id) }
    let(:user_id) { "SOMDFINKETHING_ID" }
    let(:phones) {double(:select => double("select")) }
    let(:addresses) {double(:select => double("select")) }
    let(:emails) {double(:select => double("select")) }
    let(:person) { double(:phones => phones, :addresses => addresses, :emails => emails)}
    let(:person_parameters) { ActionController::Parameters.new(:first_name => "SOMDFINKETHING").permit(:first_name,:user_id) }
    let(:more_params){{:create_person => "create", person: person_parameters}}
    let(:found_person) { [] }
    let(:mock_employee_candidate) { instance_double("Forms::EmployeeCandidate", :valid? => validation_result) }
    let(:save_result) {true}

    before(:each) do
      allow(user).to receive(:instantiate_person).and_return(person)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:agent?).and_return(false)
      allow(person).to receive(:attributes=).and_return(person_parameters)
      allow(person).to receive(:save).and_return(save_result)
      sign_in(user)
      allow(Forms::EmployeeCandidate).to receive(:new).with(person_parameters.merge({user_id: user_id})).and_return(mock_employee_candidate)
      allow(mock_employee_candidate).to receive(:match_person).and_return(found_person)
      post :match, params: more_params
    end

    context "it should create person when create person button is clicked" do
      let(:validation_result) { true }

      it "should call edit method" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("edit")
      end
    end
  end

  describe "POST match" do
    let(:user) { double(id: user_id) }
    let(:person) { double("person")}
    let(:user_id) { "SOMDFINKETHING_ID" }
    let!(:person_parameters) { ActionController::Parameters.new(:first_name => "SOMDFINKETHING").permit(:first_name,:user_id) } 
    let(:found_person) { [] }
    let(:mock_employee_candidate) { instance_double("Forms::EmployeeCandidate", :valid? => validation_result) }

    before(:each) do
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:agent?).and_return(false)
      sign_in(user)
      allow(Forms::EmployeeCandidate).to receive(:new).with(person_parameters.merge({user_id: user_id})).and_return(mock_employee_candidate)
      allow(mock_employee_candidate).to receive(:match_person).and_return(found_person)
      post :match, params: {:person => person_parameters}
    end

    context "given invalid parameters" do
      let(:validation_result) { false }

      it "renders the 'search' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("search")
        expect(assigns[:employee_candidate]).to eq mock_employee_candidate
      end
    end

    context "given valid parameters render 'no_match' template" do
      let(:validation_result) { true }

      it "renders the 'no_match' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("no_match")
        expect(assigns[:employee_candidate]).to eq mock_employee_candidate
        expect(assigns(:person).class).to eq Person
      end

    end

    context "given valid parameters render 'match' template" do
      let(:validation_result) { true }
      let(:found_person) { FactoryBot.create(:person) }

      it "renders the 'match' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("match")
        expect(assigns[:employee_candidate]).to eq mock_employee_candidate
      end
    end
  end

  describe "POST update" do
    let(:person_parameters) { { :first_name => "SOMDFINKETHING", :last_name => "SOME"} }
    let(:person) { double(:phones => double(:each => double("each")),
      :addresses => double(:each => double("each")),
      :emails => double(:each => double("each"))
     ) }
    let(:person_id){ "1234"}
    let(:address_attributes) { double(:address => ["address"])}
    let(:phone_attributes) { double(:phone => ["phone"])}
    let(:email_attributes) { double(:email => ["email"])}
    let(:valid_params){ {
      id: person_id,
      person: person_parameters.
      deep_merge(addresses_attributes: {0 => {"id" => address_attributes}}).
      deep_merge(phones_attributes: {0 => {"id" => phone_attributes}}).
      deep_merge(emails_attributes: {0 => {"id" => email_attributes}})
      } }
    let(:user) { FactoryBot.create(:user) }

    before(:each) do
      sign_in(user)
      allow(Person).to receive(:find).with(person_id).and_return(person)
      allow(person).to receive(:employer_contact).and_return("test")
      allow(person).to receive(:updated_by=).and_return("test")
      allow(person).to receive(:update_attributes).and_return(save_result)
      put :update, params: valid_params
    end

    context "given valid person parameters" do
      let(:save_result) { true }

      it "should render 'employer_form'" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("employer_form")
      end
    end
  end
end
