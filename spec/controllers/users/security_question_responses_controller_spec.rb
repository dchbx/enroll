require 'rails_helper'

RSpec.describe Users::SecurityQuestionResponsesController do
  let(:user) { double(:user, email: 'test@example.com', id: '1', person: person, security_question_responses: []) }
  let(:person) { double("Person", has_active_consumer_role?: true)}
  let(:security_question_one) { create(:security_question, title: "What was your dog's name?")}
  let(:security_question_two) { create(:security_question, title: "What elementary school did you attend?")}
  let(:security_question_three) { create(:security_question, title: "What is your favorite color?")}
  let(:first_security_response) { double(:security_question_response, security_question_id: security_question_one.id, question_answer: 'Pluto') }
  let(:security_question_responses) { [
                          { security_question_id: first_security_response.security_question_id, question_answer: first_security_response.question_answer },
                          { security_question_id: security_question_two.id, question_answer: 'Wayside' },
                          { security_question_id: security_question_three.id, question_answer: 'Mauve' }
                        ] }

  before do
    allow(User).to receive(:find).with(user.id).and_return(user)
    allow(user).to receive(:security_question_responses).and_return(security_question_responses)
  end

  describe 'POST create' do
    before :each do
      sign_in user
    end

    context "with a successful save" do
      before do
        allow(user).to receive(:save!).and_return(true)
        xhr :post, :create, { user_id: user.id, security_question_responses: security_question_responses }
      end
      it { expect(assigns(:user)).to eq(user) }
      it { expect(response).to have_http_status(:success) }
      it { expect(response).to render_template('users/security_question_responses/create') }
    end

    context "with an error on save" do
      before do
        allow(controller.request).to receive(:referrer).and_return('http://example.com')
        allow(user).to receive(:save!).and_return(false)
        xhr :post, :create, { user_id: user.id, security_question_responses: security_question_responses }
      end
      it { expect(assigns(:url)).to eq('http://example.com') }
      it { expect(response).to have_http_status(:success) }
      it { expect(response).to render_template('users/security_question_responses/error_response') }
    end
  end

  describe 'POST challenge' do
    let(:email) { user.email }

    before do
      allow(User).to receive(:find_by).with(email: user.email).and_return(user)
      allow(User).to receive(:find_by).with(email: 'invalid@example.com').and_return(nil)
      xhr :post, :challenge, { user: { email: email } }
    end

    context "for a valid email with no question responses" do
      let(:security_question_responses) { [] }

      it { expect(assigns(:user)).to eq(user) }
      it { expect(response).to have_http_status(:success) }
      it { expect(response).to render_template('users/security_question_responses/error_response') }
    end

    context "for a valid email" do
      it { expect(assigns(:user)).to eq(user) }
      it { expect(response).to have_http_status(:success) }
      it { expect(response).to render_template('users/security_question_responses/challenge') }
    end

    context "for an invalid email" do
      let(:email) { 'invalid@example.com' }

      it { expect(assigns(:user)).to be_nil }
      it { expect(response).to have_http_status(:success) }
      it { expect(response).to render_template('users/security_question_responses/error_response') }
    end
  end

  describe 'POST authenticate' do
    let(:correct_answer) { 'Pluto' }
    let(:successful_response) { { security_question_id: security_question_one.id, question_answer: correct_answer } }
    let(:security_question_responses) { double() }
    let(:correct_response) { first_security_response.question_answer}
    let(:matching) { true }

    before do
      allow(security_question_responses).to receive(:where).with(security_question_id: security_question_one.id).and_return([first_security_response])
      allow(first_security_response).to receive(:matching_response?).with(correct_response.downcase).and_return(matching)
      allow(first_security_response).to receive(:success_token).and_return('SUCCESS')

      allow(user).to receive(:identity_confirmed_token=).with('SUCCESS')
      allow(user).to receive(:save!).and_return(true)

      xhr :post, :authenticate, { user_id: user.id, security_question_response: successful_response }
    end

    context "a matching response" do
      it { expect(assigns(:user)).to eq(user) }
      it { expect(assigns(:success_token)).to eq("SUCCESS") }
      it { expect(response).to have_http_status(:success) }
      it { expect(response).to render_template('users/security_question_responses/authenticate') }
    end

    context "an invalid response" do
      let(:matching) { false }

      it { expect(assigns(:user)).to eq(user) }
      it { expect(assigns(:success_token)).to be_nil }
      it { expect(response).to have_http_status(:success) }
      it { expect(response).to render_template('users/security_question_responses/error_response') }
    end
  end

end
