require 'rails_helper'

RSpec.describe Exchanges::EmployerApplicationsController, dbclean: :after_each do

  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:employee_role1) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let!(:plan_year) {FactoryGirl.create(:plan_year, employer_profile: employer_profile, aasm_state: 'active')}
  let(:benefit_group) {FactoryGirl.create(:benefit_group, plan_year: plan_year)}
  let(:benefit_group_assignment1) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)}
  let(:benefit_group_assignment2) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)}
  let(:census_employee1) { FactoryGirl.create(:census_employee, benefit_group_assignments: [benefit_group_assignment1],employee_role_id: employee_role1.id,employer_profile_id: employer_profile.id) }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member,person: person) }

  describe ".index" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true) }

    before :each do
      sign_in(user)
      xhr :get, :index, employers_action_id: "employers_action_#{employer_profile.id}"
    end

    it "should render index" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/employer_applications/index")
    end

    context 'when hbx staff role missing' do
      let(:user) { instance_double("User", :has_hbx_staff_role? => false) }

      it 'should redirect when hbx staff role missing' do
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to('/')
      end
    end
  end

  describe ".edit" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true) }

    before :each do
      sign_in(user)
      xhr :get, :edit, id: plan_year.id, employer_id: employer_profile.id, format: :js
    end

    it "should render edit" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/employer_applications/edit")
    end
  end

  describe "PUT terminate" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true) }

    before :each do
      sign_in(user)
      put :terminate, employer_application_id: plan_year.id, employer_id: employer_profile.id, end_on: plan_year.start_on.next_month
    end

    it "should redirect to root path" do
      expect(response).to redirect_to exchanges_hbx_profiles_root_path
    end

    it "should terminate the plan year" do
      plan_year.reload
      expect(plan_year.aasm_state).to eq "termination_pending"
      expect(flash[:notice]).to eq "Employer Application terminated successfully."
    end
  end

  describe "PUT cancel" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true) }

    before :each do
      sign_in(user)
      plan_year.update_attributes!(:aasm_state => "enrolling")
      put :cancel, employer_application_id: plan_year.id, employer_id: employer_profile.id, end_on: plan_year.start_on.next_month
    end

    it "should redirect to root path" do
      expect(response).to redirect_to exchanges_hbx_profiles_root_path
    end

    it "should cancel the plan year" do
      plan_year.reload
      expect(plan_year.aasm_state).to eq "canceled"
      expect(flash[:notice]).to eq "Employer Application canceled successfully."
    end
  end
end