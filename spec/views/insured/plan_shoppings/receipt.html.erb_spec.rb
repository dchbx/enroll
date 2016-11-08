require "rails_helper"

RSpec.describe "insured/plan_shoppings/receipt.html.erb" do

  def new_member
    random_value = rand(999_999_999)
    instance_double(
      "HbxEnrollmentMember",
      primary_relationship: "self:#{random_value}",
      person: new_person(random_value)
    )
  end

  def enrollment
    instance_double(
      "HbxEnrollment",
      updated_at: TimeKeeper.date_of_record,
      hbx_enrollment_members: members,
      effective_on: TimeKeeper.date_of_record.beginning_of_month,
      plan: new_plan,
      employee_role: double("EmployeeRole")
    )
  end

  def new_person(random_value)
    instance_double(
      "Person",
      full_name: "John Doe:#{random_value}",
      age_on: 21,
      dob: double("dob")
    )
  end

  def new_plan
    double(
      "Plan",
      name: "My Silly Plan"
    )
  end

  def plan_cost_decorator
    double(
      "PlanCostDecorator",
      name: new_plan.name,
      premium_for: double("premium_for"),
      employer_contribution_for: double("employer_contribution_for"),
      employee_cost_for: double("employee_cost_for"),
      total_premium: double("total_premium"),
      total_employer_contribution: double("total_employer_contribution"),
      total_employee_cost: double("total_employee_cost"),
      carrier_profile: double(legal_name: "carefirst"),
      metal_level: "Silver",
      coverage_kind: "health"
    )
  end

  let(:members) { [new_member, new_member] }

  before :each do
    assign :enrollment, enrollment
    @plan = plan_cost_decorator
    allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true)) 
    render file: "insured/plan_shoppings/receipt.html.erb"
  end

  it "should match the data on the confirmation receipt" do
    #expect(rendered).to have_selector('p', text: "Your enrollment has been submitted as of #{enrollment.updated_at}.")
    expect(rendered).to have_selector('p', text: /Your enrollment has been submitted as/)
    expect(rendered).to have_selector('p', text: /Please print this page for your records. A copy of this confirmation/)
  end

  it "should match the enrollment memebers" do
    enrollment.hbx_enrollment_members.each do |enr_member|
      expect(rendered).to match(/#{enr_member.person.full_name}/m)
      expect(rendered).to match(/#{enr_member.primary_relationship}/m)
      expect(rendered).to match(/#{dob_in_words(enr_member.person.age_on(Time.now.utc.to_date),enr_member.person.dob)}/m)
      expect(rendered).to match(/#{@plan.premium_for(enr_member)}/m)
      expect(rendered).to match(/#{@plan.employer_contribution_for(enr_member)}/m)
      expect(rendered).to match(/#{@plan.employee_cost_for(enr_member)}/m)
      expect(rendered).to match(/#{@plan.total_premium(enr_member)}/m)
      expect(rendered).to match(/#{@plan.total_employer_contribution(enr_member)}/m)
      expect(rendered).to match(/#{@plan.total_employee_cost(enr_member)}/m)
    end
  end

  it "should have print area" do
    expect(rendered).to have_selector('#printArea')
    expect(rendered).to have_selector('a#btnPrint')
  end
end
