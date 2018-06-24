require 'rails_helper'
require 'pry'

RSpec.describe "insured/families/_shop_for_plans_widget.html.erb" do
  let(:person) { FactoryGirl.build(:person) }
  let(:family) { FactoryGirl.build(:family, :with_primary_family_member) }
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
      assign :family, family
      sign_in(current_user)
      allow(employee_role).to receive(:is_eligible_to_enroll_without_qle?).and_return(true)
      allow(employee_role).to receive(:is_under_open_enrollment?).and_return(true)
      allow(current_user).to receive(:has_employee_role?).and_return(true)
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      #allow(view).to receive(:has_active_sep?).and_return(false)
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
      assign :family, family
      assign :employee_role, employee_role
      assign :hbx_enrollments, []
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
      allow(employee_role).to receive(:is_eligible_to_enroll_without_qle?).and_return(true)
      allow(employee_role).to receive(:census_employee).and_return(census_employee)
      allow(view).to receive(:is_under_open_enrollment?).and_return(true)
      sign_in(current_user)
    end

    context "during non-open enrollment period" do
      before :each do
        allow(view).to receive(:is_under_open_enrollment?).and_return(false)
        @employee_role = employee_role
        allow(employee_role).to receive(:is_under_open_enrollment?).and_return(false)
      end

      it "should not have the text 'You are not under open enrollment period.'" do
        render "insured/families/shop_for_plans_widget"
        expect(rendered).not_to have_content "You are not under open enrollment period."
      end
    end

    it "should have the updated description with link to 'enroll today' text" do
      render "insured/families/shop_for_plans_widget"
      expect(rendered).to have_content 'coverage will begin'
      expect(rendered).to have_link('enroll today')
      expect(rendered).not_to have_content 'for Open Enrollment Period.'
    end

    it "should action to new insured group selection path" do
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

  context "without employee or consumer role" do
    before :each do
      assign :person, person
      sign_in(current_user)
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      render "insured/families/shop_for_plans_widget"
    end

    it "should have text about enrolling in Individual Market" do
      expect(rendered).to have_text("You have no Employer Sponsored Insurance. If you wish to purchase insurance, please enroll in the Individual Market.")
    end
  end

  context "dual role person with IVL sep" do
    let(:qle) { double("QualifyingLifeEventKind", title: "", market_kind: "Individual")}
    let(:sep) { double("SpecialEnrollmentPeriod", qualifying_life_event_kind: qle)}
    before :each do
      assign :person, person
      assign :family, family
      sign_in(current_user)
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      allow(person).to receive(:active_employee_roles).and_return [employee_role]
      allow(family).to receive(:latest_active_sep).and_return sep
      render "insured/families/shop_for_plans_widget"
    end

    it "should have SEP eligible text in pop up window" do
      expect(rendered).to have_content "You qualify for a Special Enrollment Period (SEP) because you"
    end
  end
end
