require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
describe Insured::InteractiveIdentityVerificationsController do

  describe "GET #new" do
    let(:mock_person) { double }
    let(:mock_user) { double(:person => mock_person) }
    let(:mock_service) { instance_double("::IdentityVerification::InteractiveVerificationService") }
    let(:mock_service_result) { instance_double("::IdentityVerification::InteractiveVerificationResponse", :failed? => service_failed, :to_model => mock_session) }
    let(:mock_session) { double }
    let(:mock_template_result) { double }

    before :each do
      sign_in(mock_user)
      allow(::IdentityVerification::InteractiveVerificationService).to receive(:new).and_return(mock_service)
      allow(controller).to receive(:render_to_string).with(
        "events/identity_verification/interactive_session_start",
        {
          :formats => ["xml"],
          :locals => { :individual => mock_person }
        }).and_return(mock_template_result)
    end

    describe "when the initial request results in failure" do
      let(:service_failed) { true }

      it "should render the 'please call' message" do
        allow(mock_service).to receive(:initiate_session).with(mock_template_result).and_return(mock_service_result)
        get :new
        expect(assigns[:verification_response]).to eq mock_service_result
        expect(response).to render_template("failed_validation")
      end
    end

    describe "when the initial request results in service unavailable" do
      it "should render the 'try back later' message" do
        allow(mock_service).to receive(:initiate_session).with(mock_template_result).and_return(nil)
        get :new
        expect(response).to render_template("service_unavailable")
      end
    end


    describe "when the initial request returns questions" do
      let(:service_failed) { false }
      it "should render the question response form" do
        expect(controller).to receive(:render_to_string).with(
          "events/identity_verification/interactive_session_start",
          {
            :formats => ["xml"],    
            :locals => { :individual => mock_person }
          }).and_return(mock_template_result)
        allow(mock_service).to receive(:initiate_session).with(mock_template_result).and_return(mock_service_result)
        get :new
        expect(assigns[:interactive_verification]).to eq mock_session
        expect(response).to render_template("new")
      end
    end
  end

  describe "POST #create" do
    let(:mock_person_user) { instance_double("User") }
    let(:mock_consumer_role) { instance_double("ConsumerRole", id: "test") }
    let(:mock_person) { double(:consumer_role => mock_consumer_role, :user => mock_person_user) }
    let(:mock_user) { double(:person => mock_person) }
    let(:mock_service) { instance_double("::IdentityVerification::InteractiveVerificationService") }
    let(:mock_response_description_text) { double }
    let(:mock_transaction_id) { double }
    let(:mock_service_result) { double(:successful? => service_succeeded, :response_text => mock_response_description_text, :transaction_id => mock_transaction_id) }
    let(:mock_session) { instance_double("::IdentityVerification::InteractiveVerification", :valid? => valid_verification) }
    let(:mock_template_result) { double }
    let(:expected_params) { verification_params }
    let(:mock_today) { double }

    before :each do
      sign_in(mock_user)
      allow(::IdentityVerification::InteractiveVerification).to receive(:new).with(expected_params).and_return(mock_session)
    end

    describe "with an invalid interactive_verification" do
      let(:verification_params) { { :whine_more => "sure why not" } }
      let(:valid_verification) { false }
      it "should render new" do
        post :create, { "interactive_verification" => verification_params }
        expect(assigns[:interactive_verification]).to eq mock_session
        expect(response).to render_template("new")
      end
    end

    describe "with valid interactive_verification" do
      let(:verification_params) { 
        { 
          :session_id => "abcde", :transaction_id => "abcdef",
          :questions_attributes => {
            "0" => {
              "question_id" => "1",
              "question_text" => "some text here",
              "response_id" => "234566",
              "responses_attributes" => {
                "0" => {
                  "response_text" => "r_text",
                  "response_id" => "r_id"
                }
              }
            }
          }
        }
      }
      let(:valid_verification) { true }

      before :each do
        allow(::IdentityVerification::InteractiveVerificationService).to receive(:new).and_return(mock_service)
        allow(controller).to receive(:render_to_string).with(
          "events/identity_verification/interactive_questions_response",
          {
            :formats => ["xml"],
            :locals => { :session => mock_session }
          }).and_return(mock_template_result)
        allow(mock_service).to receive(:respond_to_questions).with(mock_template_result).and_return(mock_service_result)
      end

      describe "when the service is unreachable" do
        let(:mock_service_result) { nil }

        it "should render the 'try back later' message" do
          post :create, { "interactive_verification" => verification_params }
          expect(response).to render_template("service_unavailable")
        end
      end

      describe "when verification is not successful" do
        let(:service_succeeded) { false }
        it "should render the 'please call' message" do
          post :create, { "interactive_verification" => verification_params }
          expect(assigns[:verification_response]).to eq mock_service_result
          expect(response).to render_template("failed_validation")
        end
      end

      describe "when verification is successful" do
        let(:service_succeeded) { true }
        it "should redirect the user" do
          allow(TimeKeeper).to receive(:date_of_record).and_return(mock_today)
          expect(mock_person_user).to receive(:identity_final_decision_code=).with(User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE)
          expect(mock_person_user).to receive(:identity_response_code=).with(User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE)
          expect(mock_person_user).to receive(:identity_response_description_text=).with(mock_response_description_text)
          expect(mock_person_user).to receive(:identity_final_decision_transaction_id=).with(mock_transaction_id)
          expect(mock_person_user).to receive(:identity_verified_date=).with(mock_today)
          expect(mock_person_user).to receive(:save!)
          post :create, { "interactive_verification" => verification_params }
          expect(response).to be_redirect
        end
      end
    end
  end

  describe "POST #update" do
    let(:mock_person_user) { instance_double("User") }
    let(:mock_consumer_role) { instance_double("ConsumerRole", id: "test") }
    let(:mock_person) { double(:consumer_role => mock_consumer_role, :user => mock_person_user) }
    let(:mock_user) { double(:person => mock_person) }
    let(:mock_service) { instance_double("::IdentityVerification::InteractiveVerificationService") }
    let(:mock_response_description_text) { double }
    let(:mock_transaction_id) { double }
    let(:mock_service_result) { double(:successful? => service_succeeded, :response_text => mock_response_description_text, :transaction_id => mock_transaction_id) }
    let(:mock_template_result) { double }
    let(:expected_params) { verification_params }
    let(:mock_today) { double }
    let(:transaction_id) { "aadsdlkmcee" }

    let(:service_succeeded) { false }

    before :each do
      sign_in(mock_user)
      allow(::IdentityVerification::InteractiveVerificationService).to receive(:new).and_return(mock_service)
      allow(controller).to receive(:render_to_string).with(
        "events/identity_verification/interactive_verification_override",
        {
          :formats => ["xml"],
          :locals => { :transaction_id => transaction_id }
        }).and_return(mock_template_result)
      allow(mock_service).to receive(:check_override).with(mock_template_result).and_return(mock_service_result)
    end

    describe "when the service is unreachable" do
      let(:mock_service_result) { nil }

      it "should render the 'try back later' message" do
        post :update, { "id" => transaction_id }
        expect(response).to render_template("service_unavailable")
      end
    end

    describe "when verification is not successful" do
      let(:service_succeeded) { false }
      it "should render the 'please call' message" do
        post :update, { "id" => transaction_id }
        expect(assigns[:verification_response]).to eq mock_service_result
        expect(response).to render_template("failed_validation")
      end
    end

    describe "when verification is successful" do
      let(:service_succeeded) { true }
      it "should redirect the user" do
        allow(TimeKeeper).to receive(:date_of_record).and_return(mock_today)
        expect(mock_person_user).to receive(:identity_final_decision_code=).with(User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE)
        expect(mock_person_user).to receive(:identity_response_code=).with(User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE)
        expect(mock_person_user).to receive(:identity_response_description_text=).with(mock_response_description_text)
        expect(mock_person_user).to receive(:identity_final_decision_transaction_id=).with(mock_transaction_id)
        expect(mock_person_user).to receive(:identity_verified_date=).with(mock_today)
        expect(mock_person_user).to receive(:save!)
        post :update, { "id" => transaction_id }
        expect(response).to be_redirect
      end
    end
  end
end
end
