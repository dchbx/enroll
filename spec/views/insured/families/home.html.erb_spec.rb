require 'rails_helper'

RSpec.describe "insured/families/home.html.erb" do
  let(:person) {FactoryGirl.create(:person, :with_employee_role, :with_family)} #let(:person) { FactoryGirl.create(:person, :with_family ) }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }

  let(:qle_first_of_month) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_first_of_month, ) }
  let(:sep){
    sep = family.special_enrollment_periods.new
    sep.effective_on_kind = 'first_of_month'
    sep.qualifying_life_event_kind= qle_first_of_month
    sep.qualifying_life_event_kind_id = qle_first_of_month.id
    sep.qle_on= Date.new(TimeKeeper.date_of_record.year, 04, 14)
    sep.admin_flag = true
    sep
  }

  before :each do
    stub_template "insured/families/_right_column.html.erb" => ''
    stub_template "insured/families/_qle_detail.html.erb" => ''
    stub_template "insured/families/_enrollment.html.erb" => ''
    stub_template "insured/families/_navigation.html.erb" => ''
    stub_template "insured/families/_shop_for_plans_widget.html.erb" => ''
    stub_template "insured/families/_apply_for_medicaid_widget.html.erb" => ''
    stub_template "insured/plan_shoppings/_help_with_plan.html.erb" => ''
    assign(:person, person)

    assign(:family, family)
    render file: "insured/families/home.html.erb"
  end

  it "should display the title" do
    allow(family).to receive(:active_seps).and_return(false)
    expect(rendered).to have_selector('h1', text: "My #{Settings.site.short_name}")
  end

  it "should have plan-summary area" do
    allow(family).to receive(:active_seps).and_return(false)
    expect(rendered).to have_selector('div#plan-summary')
  end

  it "should display 'existing SEP - Eligible to enroll' partial if there is an active admin SEP" do
    assign(:active_sep, sep)
    render file: "insured/families/home.html.erb"
    expect(rendered).to have_selector('div#qle-details-for-existing-sep')
  end

  it "should not display 'existing SEP - Eligible to enroll' partial if there is no active admin SEP" do
    assign(:active_sep, [])
    render file: "insured/families/home.html.erb"
    expect(rendered).to_not have_selector('div#qle-details-for-existing-sep')
  end

end
