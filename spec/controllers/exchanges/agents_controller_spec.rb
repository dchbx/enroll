require 'rails_helper'

RSpec.describe Exchanges::AgentsController do
  render_views
  let(:person_user) { FactoryGirl.create(:person, user: current_user)}
  let(:current_user){FactoryGirl.create(:user)}
  describe 'Agent Controller behavior' do
    let(:signed_in?){ true }
     before :each do
       allow(current_user).to receive(:person).and_return(person_user)
       allow(current_user).to receive(:roles).and_return ['csr']
     end

    it 'renders home for CAC' do
      person_user.csr_role = FactoryGirl.build(:csr_role, cac: true)
      sign_in current_user
      get :home
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/agents/home")
      expect(response.body).to match(/Certified Applicant Counselor/)
    end

    it 'renders home for CSR' do
      person_user.csr_role = FactoryGirl.build(:csr_role, cac: false)
      sign_in current_user
      get :home
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/agents/home")
    end

    it 'begins enrollment' do
      sign_in current_user
      get :begin_employee_enrollment
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "resume enrollment method behavior", dbclean: :after_each do
    let!(:consumer_role) { FactoryGirl.create(:consumer_role, bookmark_url: nil, person: person_user) }

    before(:each) do
      allow(current_user).to receive(:roles).and_return ['consumer']
      controller.class.skip_before_filter :check_agent_role
    end
    context "actions when not passed Ridp" do
      it 'should redirect to family account path' do
        sign_in current_user
        get :resume_enrollment, person_id: person_user.id
        expect(response).to redirect_to family_account_path
      end

      it 'should redirect to consumer role bookmark url' do
        consumer_role.update_attributes(bookmark_url: '/')
        sign_in current_user
        get :resume_enrollment, person_id: person_user.id
        expect(response).to redirect_to person_user.consumer_role.bookmark_url
      end
    end

    context "when admin submitted paper application" do

      before do
        consumer_role.update_attributes(bookmark_url: '/')
        sign_in current_user
      end

      it "should not redirect to family account path if not paper application" do
        get :resume_enrollment, person_id: person_user.id, original_application_type: "not_paper"
        expect(response).not_to redirect_to family_account_path
      end

      it "should redirect to family account path if admin submitted paper application" do
        get :resume_enrollment, person_id: person_user.id, original_application_type: "paper"
        expect(response).to redirect_to family_account_path
      end
    end
  end
end
