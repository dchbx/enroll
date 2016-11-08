require 'rails_helper'

RSpec.describe Exchanges::AgentsController do
  describe 'Agent Controller behavior' do
    render_views
    let(:person_user){Person.new(first_name: 'fred', last_name: 'flintstone')}
    let(:current_user){FactoryGirl.create(:user)}
    let(:signed_in?){ true }
   
     before :each do
       allow(current_user).to receive(:person).and_return(person_user)
     end

    it 'renders home for CAC' do
      current_user.roles=['csr']
      current_user.person = person_user
      person_user.csr_role = FactoryGirl.build(:csr_role, cac: true)
      sign_in current_user
      get :home
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/agents/home")
      expect(response.body).to match(/Certified Applicant Counselor/)
    end

    it 'renders home for CSR' do
      current_user.roles=['csr']
      current_user.person = person_user
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

  describe "resume enrollment method behavior" do
    context "actions when not passed Ridp" do
      let(:person_user){Person.new(first_name: 'fred', last_name: 'flintstone')}
      let(:current_user){FactoryGirl.create(:user)}
      before(:each) do
        controller.class.skip_before_filter :check_agent_role
      end

      it 'should redirect to family account path' do
        current_user.roles=['consumer']
        current_user.person = person_user
        FactoryGirl.create(:consumer_role, bookmark_url: nil, person: person_user)
        sign_in current_user
        get :resume_enrollment, person_id: person_user.id
        expect(response).to redirect_to family_account_path
      end

      it 'should redirect to consumer role bookmark url' do
        current_user.roles=['consumer']
        current_user.person = person_user
        FactoryGirl.create(:consumer_role, bookmark_url: '/', person: person_user)
        sign_in current_user
        get :resume_enrollment, person_id: person_user.id
        expect(response).to redirect_to person_user.consumer_role.bookmark_url
      end
    end


    context "When passed RIDP and having enrollment" do
      let(:person_user) { FactoryGirl.create(:person, :with_consumer_role, :with_family) }
      let(:current_user){FactoryGirl.create(:user)}
      let(:family) { FactoryGirl.create(:family, person: person_user) }
      let(:household) { FactoryGirl.create(:household, family: person_user.primary_family) }
      let(:enrollment) { FactoryGirl.create(:hbx_enrollment, household: person_user.primary_family.latest_household, kind: "individual", is_active: true)}

      before do
        allow(household).to receive(:hbx_enrollments).with(:first).and_return enrollment
        controller.class.skip_before_filter :check_agent_role
      end
      it 'should redirect to consumer role bookmark url' do
        current_user.roles=['consumer']
        current_user.person = person_user
        FactoryGirl.create(:consumer_role, bookmark_url: '/', person: person_user)
        person_user.user.update_attribute(:idp_verified, true)
        person_user.user.ridp_by_payload!
        sign_in current_user
        get :resume_enrollment, person_id: person_user.id
        person_user.reload
        expect(person_user.consumer_role.bookmark_url).to eq '/families/home'
        expect(response).to redirect_to '/families/home'
      end
    end
  end
end
