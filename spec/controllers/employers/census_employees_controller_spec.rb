  require 'rails_helper'

RSpec.describe Employers::CensusEmployeesController do

  before(:all) do
    @user = FactoryGirl.create(:user)
    p=FactoryGirl.create(:person, user: @user)
    @hbx_staff_role = FactoryGirl.create(:hbx_staff_role, person: p)
  end
  # let(:employer_profile_id) { "abecreded" }
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:employer_profile_id) { employer_profile.id }

  let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id, employment_terminated_on: TimeKeeper::date_of_record - 45.days,  hired_on: "2014-11-11") }
  let(:census_employee_params) {
    {"first_name" => "aqzz",
     "middle_name" => "",
     "last_name" => "White",
     "gender" => "male",
     "is_business_owner" => true,
     "hired_on" => "05/02/2015",
     "employer_profile_id" => employer_profile_id} }

  let(:person) { FactoryGirl.create(:person, first_name: "aqzz", last_name: "White", dob: "11/11/1992", ssn: "123123123", gender: "male", employer_profile_id: employer_profile.id, hired_on: "2014-11-11")}
  describe "GET new" do

    it "should render the new template" do
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(employer_profile).to receive(:plan_years).and_return("2015")
      allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
      sign_in(@user)
      get :new, :employer_profile_id => employer_profile_id
      expect(response).to have_http_status(:success)
      expect(response).to render_template("new")
      expect(assigns(:census_employee).class).to eq CensusEmployee
    end

    it "should render as normal with no plan_years" do
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(employer_profile).to receive(:plan_years).and_return("")
      allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
      sign_in(@user)
      get :new, :employer_profile_id => employer_profile_id
      expect(response).to have_http_status(:success)
      expect(response).to render_template("new")
    end

  end

  describe "POST create" do
    let(:benefit_group) { double(id: "5453a544791e4bcd33000121") }

    before do
      allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
      sign_in @user
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(BenefitGroup).to receive(:find).and_return(benefit_group)
      allow(BenefitGroupAssignment).to receive(:new_from_group_and_census_employee).and_return([BenefitGroupAssignment.new])

      allow(controller).to receive(:benefit_group_id).and_return(benefit_group.id)
      allow(controller).to receive(:census_employee_params).and_return(census_employee_params)
      allow(CensusEmployee).to receive(:new).and_return(census_employee)
      allow(census_employee).to receive(:assign_benefit_packages).and_return(true)
    end

    it "should be redirect when valid" do
      allow(census_employee).to receive(:save).and_return(true)
      post :create, :employer_profile_id => employer_profile_id, census_employee: {}
      expect(response).to be_redirect
    end

    context "get flash notice" do
      it "with benefit_group_id" do
        allow(census_employee).to receive(:save).and_return(true)
        allow(census_employee).to receive(:active_benefit_group_assignment).and_return(true)
        post :create, :employer_profile_id => employer_profile_id, census_employee: {}
        expect(flash[:notice]).to eq "Census Employee is successfully created."
      end
    end

    it "should be render when invalid" do
      allow(census_employee).to receive(:save).and_return(false)
      post :create, :employer_profile_id => employer_profile_id, census_employee: {}
      expect(assigns(:reload)).to eq true
      expect(response).to render_template("new")
    end

    it "should return success flash notice as roster added when no ER benefits present" do
      allow(census_employee).to receive(:save).and_return(true)
      post :create, :employer_profile_id => employer_profile_id, census_employee: {}
      expect(flash[:notice]).to eq "Your employee was successfully added to your roster."
    end
  end

  describe "GET edit" do
    let(:user) { FactoryGirl.create(:user, :employer_staff) }
    it "should be render edit template" do
      sign_in user
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(CensusEmployee).to receive(:find).and_return(census_employee)
      post :edit, :id => census_employee.id, :employer_profile_id => employer_profile_id, census_employee: {}
      expect(response).to render_template("edit")
    end
  end

  describe "PUT update", dbclean: :after_each do

    let(:effective_on) { TimeKeeper.date_of_record.beginning_of_month.prev_month }
    let(:employer) {
      FactoryGirl.create(:employer_with_planyear, start_on: effective_on, plan_year_state: 'active')
    }

    let(:plan_year) { employer.plan_years[0] }
    let(:benefit_group) { plan_year.benefit_groups[0] }

    let(:user) { FactoryGirl.create(:user, :employer_staff) }
    let(:census_employee_delete_params) {
      {
        "first_name" => "aqzz",
        "middle_name" => "",
        "last_name" => "White",
        "gender" => "male",
        "is_business_owner" => true,
        "hired_on" => "05/02/2015",
        "employer_profile_id" => employer_profile_id,
        "census_dependents_attributes" => [
          {
            "id" => child1.id,
            "first_name" => child1.first_name,
            "last_name" => child1.last_name,
            "dob" => child1.dob,
            "gender" => child1.gender,
            "employee_relationship" => child1.employee_relationship,
            "ssn" => child1.ssn,
            "_destroy" => true
          }
        ]
      }
    }

    let!(:user) { create(:user, person: person)}
    let(:child1) { FactoryGirl.build(:census_dependent, employee_relationship: "child_under_26", ssn: 123123714) }
    let(:employee_role) { FactoryGirl.create(:employee_role, person: person)}
    let(:census_employee) { FactoryGirl.create(:census_employee_with_active_assignment, employer_profile_id: employer.id, hired_on: "2014-11-11", first_name: "aqzz", last_name: "White", dob: "11/11/1990", ssn: "123123123", gender: "male", benefit_group: benefit_group) }

    before do
      allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
      sign_in @user
      census_employee.census_dependents << child1
      allow(controller).to receive(:authorize).and_return(true)
    end

    it "should be redirect when valid" do
      allow(census_employee).to receive(:save).and_return(true)
      allow(controller).to receive(:census_employee_params).and_return(census_employee_params)
      post :update, :id => census_employee.id, :employer_profile_id => employer.id, census_employee: census_employee_params
      expect(response).to be_redirect
    end

    context "delete dependent params" do
      it "should delete dependents" do
        allow(controller).to receive(:census_employee_params).and_return(census_employee_delete_params)
        post :update, :id => census_employee.id, :employer_profile_id => employer.id, census_employee: census_employee_delete_params
        expect(response).to be_redirect
      end
    end

    context "get flash notice" do
      it "with benefit_group_id" do
        allow(controller).to receive(:benefit_group_id).and_return(benefit_group.id)
        post :update, :id => census_employee.id, :employer_profile_id => employer.id, census_employee: census_employee_params
        expect(flash[:notice]).to eq "Census Employee is successfully updated."
      end

      it "with no benefit_group_id" do
        post :update, :id => census_employee.id, :employer_profile_id => employer.id, census_employee: census_employee_params
        expect(flash[:notice]).to eq "Census Employee is successfully updated. Note: new employee cannot enroll on #{Settings.site.short_name} until they are assigned a benefit group."
      end
    end

    it "should be redirect when invalid" do
      allow(controller).to receive(:census_employee_params).and_return(census_employee_params)
      post :update, :id => census_employee.id, :employer_profile_id => employer.id, census_employee: census_employee_params.merge("hired_on" => nil)
      expect(response).to redirect_to(employers_employer_profile_census_employee_path(employer, census_employee, tab: 'employees'))
    end

    it "should have aasm state as eligible when there is no matching record found and employee_role_linked in reverse case" do
      expect(census_employee.aasm_state).to eq "eligible"
      allow(controller).to receive(:census_employee_params).and_return(census_employee_params.merge(dob: person.dob, census_dependents_attributes: {}))
      post :update, :id => census_employee.id, :employer_profile_id => employer.id, census_employee: {}
      expect(census_employee.reload.aasm_state).to eq "employee_role_linked"
    end
  end

  describe "GET show" do
    let(:benefit_group_assignment) { double(hbx_enrollment: hbx_enrollment, active_hbx_enrollments: [hbx_enrollment]) }
    let(:benefit_group) { double }
    let(:hbx_enrollment) { double }
    let(:hbx_enrollments) { FactoryGirl.build_stubbed(:hbx_enrollment) }

    let(:person) { FactoryGirl.create(:person)}
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:employee_role1) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
    let(:plan_year) {FactoryGirl.create(:plan_year, employer_profile: employer_profile)}
    let(:benefit_group) {FactoryGirl.create(:benefit_group, plan_year: plan_year)}
    let(:benefit_group_assignment1) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)}
    let(:benefit_group_assignment2) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)}
    let(:census_employee1) { FactoryGirl.create(:census_employee, benefit_group_assignments: [benefit_group_assignment1],employee_role_id: employee_role1.id,employer_profile_id: employer_profile.id) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member,person: person) }
    let(:current_employer_term_enrollment) do
      FactoryGirl.create(:hbx_enrollment,
                         household: family.active_household,
                         kind: "employer_sponsored",
                         employee_role_id: employee_role1.id,
                         benefit_group_assignment_id:benefit_group_assignment1.id,
                         aasm_state: 'coverage_terminated'
      )
    end
    let(:current_employer_active_enrollment) do
      FactoryGirl.create(:hbx_enrollment,
                         household: family.active_household,
                         kind: "employer_sponsored",
                         employee_role_id: employee_role1.id,
                         benefit_group_assignment_id:benefit_group_assignment1.id,
                         aasm_state: 'coverage_selected'
      )
    end
    let(:individual_term_enrollment) do
      FactoryGirl.create(:hbx_enrollment,
                         household: family.active_household,
                         kind: "individual",
                         aasm_state: 'coverage_terminated'
      )
    end
    let(:old_employer_term_enrollment) do
      FactoryGirl.create(:hbx_enrollment,
                         household: family.active_household,
                         kind: "employer_sponsored",
                         benefit_group_assignment_id:benefit_group_assignment2.id,
                         aasm_state: 'coverage_terminated'
      )
    end
    let(:expired_enrollment) do
      FactoryGirl.create(:hbx_enrollment,
                         household: family.active_household,
                         kind: "individual",
                         aasm_state: 'coverage_expired'
      )
    end
    it "should be render show template" do
      allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return(hbx_enrollments)
      allow(benefit_group_assignment).to receive(:benefit_group).and_return(benefit_group)
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(CensusEmployee).to receive(:find).and_return(census_employee)
      get :show, :id => census_employee.id, :employer_profile_id => employer_profile_id
      expect(response).to render_template("show")
    end

    it "should return employer_sponsored past enrollment matching benefit_group_assignment_id of current employee role " do
      sign_in
      allow(CensusEmployee).to receive(:find).and_return(census_employee1)
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:all_enrollments).and_return([current_employer_term_enrollment,current_employer_active_enrollment,old_employer_term_enrollment])
      get :show, :id => census_employee1.id, :employer_profile_id => employer_profile_id
      expect(response).to render_template("show")
      expect(assigns(:past_enrollments)).to eq([current_employer_term_enrollment])
    end

    it "should not return IVL enrollment in past enrollment of current employee role " do
      sign_in
      allow(CensusEmployee).to receive(:find).and_return(census_employee1)
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:all_enrollments).and_return([current_employer_term_enrollment,individual_term_enrollment,current_employer_active_enrollment])
      get :show, :id => census_employee1.id, :employer_profile_id => employer_profile_id
      expect(response).to render_template("show")
      expect(assigns(:past_enrollments)).to eq([current_employer_term_enrollment])
    end

    it "enrollment should not be included in past enrollments that doesn't match's current employee benefit_group_assignment_id " do
      sign_in
      allow(CensusEmployee).to receive(:find).and_return(census_employee1)
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:all_enrollments).and_return([current_employer_term_enrollment,current_employer_active_enrollment,old_employer_term_enrollment])
      get :show, :id => census_employee1.id, :employer_profile_id => employer_profile_id
      expect(response).to render_template("show")
      expect(assigns(:past_enrollments)).to eq([current_employer_term_enrollment])
    end

    context "for past enrollments" do
      let(:census_employee) { FactoryGirl.build(:census_employee, first_name: person.first_name, last_name: person.last_name, dob: person.dob, ssn: person.ssn, employee_role_id: employee_role.id)}
      let(:household) { FactoryGirl.create(:household, family: person.primary_family)}
      let(:employee_role) { FactoryGirl.create(:employee_role, person: person)}
      let(:person) { FactoryGirl.create(:person, :with_family)}
      let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: census_employee.employee_role.person.primary_family.households.first)}
      let!(:hbx_enrollment_two) { FactoryGirl.create(:hbx_enrollment, household: census_employee.employee_role.person.primary_family.households.first)}

      it "should not have any past enrollments" do
        hbx_enrollment.update_attribute(:aasm_state, "coverage_canceled")
        sign_in
        allow(CensusEmployee).to receive(:find).and_return(census_employee)
        get :show, :id => census_employee.id, :employer_profile_id => employer_profile_id
        expect(response).to render_template("show")
        expect(assigns(:past_enrollments)).to eq []
      end

      it "should have a past non canceled enrollment" do
        census_employee.benefit_group_assignments << benefit_group_assignment1
        census_employee.benefit_group_assignments << benefit_group_assignment2
        hbx_enrollment.update_attributes(aasm_state: "coverage_terminated", benefit_group_assignment_id: benefit_group_assignment1.id)
        hbx_enrollment_two.update_attributes(aasm_state: "coverage_canceled", benefit_group_assignment_id: benefit_group_assignment2.id)
        sign_in
        allow(CensusEmployee).to receive(:find).and_return(census_employee)
        get :show, :id => census_employee.id, :employer_profile_id => employer_profile_id
        expect(response).to render_template("show")
        expect(assigns(:past_enrollments)).to eq [hbx_enrollment]
      end

      it "should consider all the enrollments with terminated statuses" do
        census_employee.benefit_group_assignments << benefit_group_assignment1
        census_employee.benefit_group_assignments << benefit_group_assignment2
        hbx_enrollment.update_attributes(aasm_state: "coverage_terminated", benefit_group_assignment_id: benefit_group_assignment1.id)
        hbx_enrollment_two.update_attributes(aasm_state: "unverified", benefit_group_assignment_id: benefit_group_assignment2.id)
        sign_in
        allow(CensusEmployee).to receive(:find).and_return(census_employee)
        get :show, :id => census_employee.id, :employer_profile_id => employer_profile_id
        expect(response).to render_template("show")
        expect((assigns(:past_enrollments)).size).to eq 2
      end
    end
  end

  describe "GET delink" do
    let(:census_employee) { double(id: "test", :delink_employee_role => "test", employee_role: nil, benefit_group_assignments: [benefit_group_assignment], save: true) }
    let(:benefit_group_assignment) { double(hbx_enrollment: hbx_enrollment, delink_coverage: true, save: true) }
    let(:hbx_enrollment) { double(destroy: true) }

    before do
      allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
      sign_in @user
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(CensusEmployee).to receive(:find).and_return(census_employee)
      allow(controller).to receive(:authorize).and_return(true)
    end

    it "should be redirect and successful when valid" do
      allow(census_employee).to receive(:valid?).and_return(true)

      get :delink, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id
      expect(response).to be_redirect
      expect(flash[:notice]).to eq "Successfully delinked census employee."
    end

    it "should be redirect and failure when invalid" do
      allow(census_employee).to receive(:valid?).and_return(false)
      get :delink, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id
      expect(response).to be_redirect
      expect(flash[:alert]).to eq "Delink census employee failure."
    end
  end

  describe "GET terminate" do

    before do
      allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
      sign_in @user
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(CensusEmployee).to receive(:find).and_return(census_employee)
    end
    it "should be redirect" do
      get :terminate, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id
      expect(flash[:notice]).to eq "Successfully terminated Census Employee."
      expect(response).to have_http_status(:success)
    end

    it "should throw error when census_employee terminate_employment error" do
      allow(census_employee).to receive(:terminate_employment).and_return(false)
      xhr :get, :terminate, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id, termination_date: Date.today.to_s, :format => :js
      expect(response).to have_http_status(:success)
      expect(assigns[:fa]).to eq false
      expect(flash[:error]).to eq "Census Employee could not be terminated: Termination date must be within the past 60 days."
    end

    context "with termination date" do
      it "should terminate census employee" do
        expect(controller).to receive(:notify_employee_of_termination)
        xhr :get, :terminate, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id, termination_date: Date.today.to_s, :format => :js
        expect(response).to have_http_status(:success)
        expect(assigns[:fa]).to eq census_employee
      end
    end

    context "with no termination date" do
      it "should throw error" do
        expect(controller).not_to receive(:notify_employee_of_termination)
        xhr :get, :terminate, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id, termination_date: "", :format => :js
        expect(response).to have_http_status(:success)
        expect(assigns[:fa]).to eq nil
      end
    end
  end

  describe "for cobra" do
    let(:hired_on) { TimeKeeper.date_of_record }
    let(:cobra_date) { hired_on + 10.days }
    before do
      sign_in @user
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(CensusEmployee).to receive(:find).and_return(census_employee)
      census_employee.update(aasm_state: 'employment_terminated', hired_on: hired_on, employment_terminated_on: (hired_on + 2.days))
      allow(census_employee).to receive(:build_hbx_enrollment_for_cobra).and_return(true)
      allow(controller).to receive(:authorize).and_return(true)
    end

    context 'Get cobra' do
      it "should be redirect" do
        allow(census_employee).to receive(:update_for_cobra).and_return true
        xhr :get, :cobra, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id, cobra_date: cobra_date.to_s, :format => :js
        expect(flash[:notice]).to eq "Successfully update Census Employee."
        expect(response).to have_http_status(:success)
      end

      context "with cobra date" do
        it "should cobra census employee" do
          xhr :get, :cobra, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id, cobra_date: cobra_date.to_s, :format => :js
          expect(response).to have_http_status(:success)
          expect(assigns[:cobra_date]).to eq cobra_date
        end

        it "should not cobra census_employee" do
          allow(census_employee).to receive(:update_for_cobra).and_return false
          xhr :get, :cobra, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id, cobra_date: cobra_date.to_s, :format => :js
          expect(response).to have_http_status(:success)
          expect(flash[:error]).to eq "COBRA cannot be initiated for this employee because termination date is over 6 months in the past. Please contact #{Settings.site.short_name} at #{Settings.contact_center.phone_number} for further assistance."
        end
      end

      context "without cobra date" do
        it "should throw error" do
          xhr :get, :cobra, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id, cobra_date: "", :format => :js
          expect(response).to have_http_status(:success)
          expect(assigns[:cobra_date]).to eq ""
          expect(flash[:error]).to eq "Please enter cobra date."
        end
      end
    end

    context 'Get cobra_reinstate' do
      it "should get notice" do
        allow(census_employee).to receive(:reinstate_eligibility!).and_return true
        xhr :get, :cobra_reinstate, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id, :format => :js
        expect(flash[:notice]).to eq 'Successfully update Census Employee.'
      end

      it "should get error" do
        allow(census_employee).to receive(:reinstate_eligibility!).and_return false
        xhr :get, :cobra_reinstate, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id, :format => :js
        expect(flash[:error]).to eq "Unable to update Census Employee."
      end
    end
  end

  describe "GET rehire" do
    it "should be error without rehiring_date" do
      allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
      sign_in @user
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(CensusEmployee).to receive(:find).and_return(census_employee)
      xhr :get, :rehire, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id, :format => :js
      expect(response).to have_http_status(:success)
      expect(flash[:error]).to eq "Please enter rehiring date."
    end

    context "with rehiring_date" do
      it "should be error when has no new_family" do
        allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
        sign_in @user
        allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
        allow(CensusEmployee).to receive(:find).and_return(census_employee)
        xhr :get, :rehire, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id, rehiring_date: (TimeKeeper::date_of_record + 30.days).to_s, :format => :js
        expect(response).to have_http_status(:success)
        expect(flash[:error]).to eq "Census Employee is already active."
      end

      context "when has new_census employee" do
        let(:new_census_employee) { double("test") }
        before do
          allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
          sign_in @user
          allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
          allow(CensusEmployee).to receive(:find).and_return(census_employee)
          allow(census_employee).to receive(:replicate_for_rehire).and_return(new_census_employee)
          allow(new_census_employee).to receive(:hired_on=).and_return("test")
          allow(new_census_employee).to receive(:employer_profile=).and_return("test")
          allow(new_census_employee).to receive(:address).and_return(true)
          allow(new_census_employee).to receive(:construct_employee_role_for_match_person)
          allow(new_census_employee).to receive(:add_default_benefit_group_assignment).and_return(true)
        end

        it "rehire success" do
          allow(new_census_employee).to receive(:valid?).and_return(true)
          allow(new_census_employee).to receive(:save).and_return(true)
          allow(census_employee).to receive(:valid?).and_return(true)
          allow(census_employee).to receive(:save).and_return(true)
          allow(census_employee).to receive(:rehire_employee_role).never
          xhr :get, :rehire, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id, rehiring_date: (TimeKeeper::date_of_record + 30.days).to_s, :format => :js
          expect(response).to have_http_status(:success)
          expect(flash[:notice]).to eq "Successfully rehired Census Employee."
        end

        it "when success should return new_census_employee" do
          allow(new_census_employee).to receive(:valid?).and_return(true)
          allow(new_census_employee).to receive(:save).and_return(true)
          allow(census_employee).to receive(:valid?).and_return(true)
          allow(census_employee).to receive(:save).and_return(true)
          allow(census_employee).to receive(:rehire_employee_role).never
          xhr :get, :rehire, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id, rehiring_date: (TimeKeeper::date_of_record + 30.days).to_s, :format => :js
          expect(response).to have_http_status(:success)
          expect(flash[:notice]).to eq "Successfully rehired Census Employee."
          expect(assigns(:census_employee)).to eq new_census_employee
        end

        it "when new_census_employee invalid" do
          allow(new_census_employee).to receive(:valid?).and_return(false)
          xhr :get, :rehire, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id, rehiring_date: (TimeKeeper::date_of_record + 30.days).to_s, :format => :js
          expect(response).to have_http_status(:success)
          expect(flash[:error]).to eq "Error during rehire."
        end

        it "with rehiring date before terminated date" do
          allow(census_employee).to receive(:employment_terminated_on).and_return(TimeKeeper.date_of_record)
          xhr :get, :rehire, :census_employee_id => census_employee.id, :employer_profile_id => employer_profile_id, rehiring_date: "05/01/2015", :format => :js
          expect(response).to have_http_status(:success)
          expect(flash[:error]).to eq "Rehiring date can't occur before terminated date."
        end
      end
    end
  end

  describe "GET benefit_group" do
    it "should be render benefit_group template" do
      sign_in
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(CensusEmployee).to receive(:find).and_return(census_employee)
      post :benefit_group, :id => census_employee.id, :employer_profile_id => employer_profile_id, census_employee: {}
      expect(response).to render_template("benefit_group")
    end
  end

  describe "Update census member email" do
    it "expect census employee to have a email present" do
      expect(census_employee.email.present?).to eq true
    end

    it "should allow emails to be updated to nil" do
      census_employee.email.update(address:'', kind:'')
      expect(census_employee.email.kind).to eq ''
      expect(census_employee.email.address).to eq ''
    end
  end
end
