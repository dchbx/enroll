require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe "insured/families/_shop_for_plans_widget.html.erb",dbclean: :around_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:person)  { FactoryBot.create(:person, :with_family)}
  let(:family)  { person.primary_family }
  let(:employer_profile) { abc_profile }
  let(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: abc_profile.id)}
  let(:plan_year) { initial_application }
  let(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile) }
  let(:hbx_enrollments) {double}
  let(:hbx_profile) { FactoryBot.create(:hbx_profile) }
  let(:current_user) { FactoryBot.create(:user)}
  let(:sep) { FactoryBot.create(:special_enrollment_period, family: family) }


  context "with hbx_enrollments" do
    if aca_state_abbreviation == "DC"
      before :each do
        assign :person, person
        assign :employee_role, employee_role
        assign :hbx_enrollments, hbx_enrollments
        assign :family, family
        sign_in(current_user)
        allow(employer_profile).to receive(:published_plan_year).and_return(plan_year)
        allow(employee_role).to receive(:is_eligible_to_enroll_without_qle?).and_return(true)
        allow(employee_role).to receive(:is_under_open_enrollment?).and_return(true)
        allow(employee_role).to receive(:census_employee).and_return(census_employee)
        allow(current_user).to receive(:has_employee_role?).and_return(true)
        allow(person).to receive(:active_employee_roles).and_return([employee_role])
        allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
        #allow(view).to receive(:has_active_sep?).and_return(false)
        render "insured/families/shop_for_plans_widget"
      end

      it 'should have title' do
        expect(rendered).to have_selector('strong', text: "Shop for health and dental plans")
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
  end

  context "without hbx_enrollments" do
    before :each do
      assign :person, person
      assign :employee_role, employee_role
      assign :hbx_enrollments, []
      assign :family, family
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      sign_in(current_user)

      render "insured/families/shop_for_plans_widget"
    end

    it "should have link without change_plan" do
      # Moving to cucumber as this is flickering due to unpredictable page load time and modal response
      # expect(rendered).to have_selector("a[href='/insured/consumer_role/build']")
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
      allow(employee_role).to receive(:is_under_open_enrollment?).and_return(true)
      allow(employer_profile).to receive(:published_plan_year).and_return(plan_year)
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

    context 'Employee in terminated status' do
      context 'During Employer OE' do
        before :each do
          assign :family, family
          @employee_role = employee_role
          allow(person).to receive(:active_employee_roles).and_return([employee_role])
          allow(employee_role).to receive(:is_eligible_to_enroll_without_qle?).and_return(false)
          allow(employee_role).to receive(:census_employee).and_return(census_employee)
          allow(employee_role).to receive(:is_under_open_enrollment?).and_return(true)
          allow(view).to receive(:is_under_open_enrollment?).and_return(false)
        end

        it 'should show text terminated by employer if census employee is terminated and has no active seps' do
          census_employee.update_attributes(employment_terminated_on: TimeKeeper.date_of_record)
          allow(census_employee).to receive(:is_employee_in_term_pending?).and_return(true)
          render "insured/families/shop_for_plans_widget"
          expect(rendered).to have_text "You have been terminated by your employer"
        end

        it 'should show link enroll today text if census employee is terminated with future sep which falls in renewal PY' do
          allow(census_employee).to receive(:is_employee_in_term_pending?).and_return(false)
          allow(employee_role).to receive(:benefit_begin_date).and_return(TimeKeeper.date_of_record)
          render "insured/families/shop_for_plans_widget"
          expect(rendered).to have_content 'coverage will begin'
          expect(rendered).to have_link('enroll today')
          expect(rendered).not_to have_content 'for Open Enrollment Period.'
        end

        it 'should show SEP text if census employee is terminated and has active seps' do
          allow(family).to receive(:active_seps).and_return([sep])
          allow(family).to receive(:latest_active_sep).and_return(sep)
          allow(census_employee).to receive(:is_employee_in_term_pending?).and_return(true)
          render 'insured/families/shop_for_plans_widget'
          expect(rendered).to have_text 'You qualify for a Special Enrollment Period (SEP) because you'
        end
      end

      context 'outside Employer OE' do
        before :each do
          assign :family, family
          @employee_role = employee_role
          allow(person).to receive(:active_employee_roles).and_return([employee_role])
          allow(employee_role).to receive(:is_eligible_to_enroll_without_qle?).and_return(false)
          allow(employee_role).to receive(:census_employee).and_return(census_employee)
          allow(employee_role).to receive(:is_under_open_enrollment?).and_return(false)
          allow(view).to receive(:is_under_open_enrollment?).and_return(false)
        end

        it 'should show text terminated by employer if census employee is terminated and has no active seps' do
          allow(census_employee).to receive(:is_employee_in_term_pending?).and_return(true)
          render 'insured/families/shop_for_plans_widget'
          expect(rendered).not_to have_text 'You have been terminated by your employer'
        end
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

    it "should not show the text about enrolling in Individual Market" do
      expect(rendered).not_to have_text("You have no Employer Sponsored Insurance. If you wish to purchase insurance, please enroll in the Individual Market.")
    end
  end
end
