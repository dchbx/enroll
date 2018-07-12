require 'rails_helper'

RSpec.describe Exchanges::SecurityQuestionsController, dbclean: :after_each do

  let(:user) { FactoryGirl.create(:user, with_security_questions: false) }
  let(:person) { FactoryGirl.create(:person, user: user) }
  let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person) }
  let(:question) { instance_double("SecurityQuestion", title: 'Your Question', id: '1') }

  before :each do
    allow(user).to receive(:has_hbx_staff_role?).and_return true

    allow(SecurityQuestion).to receive(:all).and_return([question])
    allow(SecurityQuestion).to receive(:find).with(question.id).and_return(question)
    sign_in user
  end

  describe 'GET index' do
    before { get :index }
    it { expect(assigns(:questions)).to eq([question]) }
    it { expect(response).to have_http_status(:success) }
    it { expect(response).to render_template('exchanges/security_questions/index') }
  end

  describe 'GET new' do
    before { get :new }
    it { expect(assigns(:question)).to be_a(SecurityQuestion) }
    it { expect(response).to have_http_status(:success) }
    it { expect(response).to render_template('exchanges/security_questions/new') }
  end

  describe 'POST create' do
    context 'When create a question with invalid params' do
      before { post :create, security_question: { title: nil } }
      it { expect(assigns(:question).title).to be_nil }
      it { expect(assigns(:question).errors.full_messages).to eq(['Title can\'t be blank']) }
      it { expect(response).to have_http_status(:success) }
      it { expect(response).to render_template('exchanges/security_questions/new') }
    end

    context 'When question is created successfully' do
      before { post :create, security_question: { title: 'First Question' } }
      it { expect(assigns(:question)).to be_a(SecurityQuestion) }
      it { expect(SecurityQuestion.all).not_to eq([]) }
      it { expect(assigns(:question).title).to eq('First Question') }
      it { expect(response).to redirect_to('/exchanges/security_questions') }
    end
  end

  describe 'GET edit' do
    before { get :edit, id: question.id }
    it { expect(assigns(:question)).to eq(question) }
    it { expect(response).to have_http_status(:success) }
    it { expect(response).to render_template('exchanges/security_questions/edit') }
  end

  describe 'PUT update' do
    let(:true_if_allowed) { true }
    let(:title) { 'Updated title' }
    before do
      allow(question).to receive(:safe_to_edit_or_delete?).and_return(true_if_allowed)
      allow(question).to receive(:update_attributes).with({ title: nil }).and_return(false)
      allow(question).to receive(:update_attributes).with({ title: 'Updated title' }).and_return(true)
      allow(question).to receive(:title).and_return(title)
      put :update, id: question.id, security_question: { title: title }
    end

    context 'When update question with valid title' do
      it { expect(assigns(:question)).to eq(question) }
      it { expect(assigns(:question).title).to eq(title) }
      it { expect(response).to redirect_to('/exchanges/security_questions') }
    end

    context "when updating a question that has been answered already" do
      let!(:true_if_allowed) { false }

      it { expect(assigns(:question)).to eq(question) }
      it { expect(response).to have_http_status(:success) }
      it { expect(response).to render_template('exchanges/security_questions/edit') }
    end

    context 'When update question with blank title' do
      let(:title) { nil }
      let(:errors) { double(:errors, full_messages: ["Title can't be blank"]) }
      before do
        allow(question).to receive(:errors).and_return(errors)
      end
      it { expect(assigns(:question)).to eq(question) }
      it { expect(assigns(:question).errors.full_messages).to eq(['Title can\'t be blank']) }
      it { expect(response).to have_http_status(:success) }
      it { expect(response).to render_template('exchanges/security_questions/edit') }
    end
  end

  describe 'DELETE destroy' do
    let(:true_if_allowed) { true }
    let(:this_many) { 1 }
    before do
      allow(question).to receive(:safe_to_edit_or_delete?).and_return(true_if_allowed)
      expect(question).to receive(:destroy).exactly(this_many).times

      delete :destroy, id: question.id
    end

    it { expect(response).to redirect_to('/exchanges/security_questions') }

    context "when attempting to delete a question that has been answered already" do
      let!(:true_if_allowed) { false }
      let(:this_many) { 0 }
      it { expect(response).to redirect_to('/exchanges/security_questions') }
    end
  end

end
