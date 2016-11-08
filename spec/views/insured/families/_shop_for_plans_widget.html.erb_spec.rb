require 'rails_helper'

RSpec.describe "insured/families/_shop_for_plans_widget.html.erb" do
  let(:person) { FactoryGirl.build(:person) }
  let(:employee_role) { FactoryGirl.build(:employee_role) }
  let(:census_employee) { FactoryGirl.build(:census_employee) }
  let(:hbx_enrollments) {double}
  let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
  let(:current_user) { FactoryGirl.create(:user)}


  context "with hbx_enrollments" do
    before :each do
      assign :person, person
      assign :employee_role, employee_role
      assign :hbx_enrollments, hbx_enrollments
      sign_in(current_user)
      allow(employee_role).to receive(:is_eligible_to_enroll_without_qle?).and_return(true)
      allow(employee_role).to receive(:is_under_open_enrollment?).and_return(true)
      allow(current_user).to receive(:has_employee_role?).and_return(true)
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      render "insured/families/shop_for_plans_widget"
    end

    it 'should have title' do
      expect(rendered).to have_selector('strong', "Browse Health and Dental plans from carriers in the DC Health Exchange")
    end

    it "should have image" do
      expect(rendered).to have_selector("img")
      expect(rendered).to match /shop_for_plan/
    end

    it "should have link with change_plan" do
      expect(rendered).to have_selector("input[type=submit][value='Shop for Plans']")
      expect(rendered).to have_selector('strong', text: 'Shop for health and dental plans')
      expect(rendered).to have_selector("a[href='/insured/group_selections/new?change_plan=change_plan&employee_role_id=#{employee_role.id}&person_id=#{person.id}&shop_for_plan=shop_for_plan']")
    end
  end

  context "without hbx_enrollments" do
    before :each do
      assign :person, person
      assign :employee_role, employee_role
      assign :hbx_enrollments, []
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      sign_in(current_user)

      render "insured/families/shop_for_plans_widget"
    end

    it "should have link without change_plan" do
      expect(rendered).to have_selector("a[href='/insured/consumer_role/build']")
    end
  end

  context "action path" do
    let(:benefit_group) { double }
    let(:new_hire_enrollment_period) { TimeKeeper.date_of_record..(TimeKeeper.date_of_record + 30.days) }

    before :each do
      assign :person, person
      assign :employee_role, employee_role
      assign :hbx_enrollments, []
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      sign_in(current_user)
    end

    it "should action to new insured group selection path" do
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
      allow(employee_role).to receive(:is_eligible_to_enroll_without_qle?).and_return(true)
      allow(employee_role).to receive(:census_employee).and_return(census_employee)
      allow(view).to receive(:is_under_open_enrollment?).and_return(true)
      render "insured/families/shop_for_plans_widget"
      expect(rendered).to have_selector("form[action='/insured/group_selections/new']")
    end

    it "should action to find sep insured families path" do
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
      allow(employee_role).to receive(:is_eligible_to_enroll_without_qle?).and_return(false)
      allow(employee_role).to receive(:census_employee).and_return(census_employee)
      allow(employee_role).to receive(:is_under_open_enrollment?).and_return(false)
      allow(view).to receive(:is_under_open_enrollment?).and_return(false)
      render "insured/families/shop_for_plans_widget"
      expect(rendered).to have_selector("form[action='/insured/families/find_sep']")
    end
  end
end
