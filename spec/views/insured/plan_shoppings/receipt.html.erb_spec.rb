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
      is_cobra_status?: false,
      coverage_kind: 'health',
      is_shop?: true,
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
      name: "My Silly Plan",
      carrier_profile: carrier_profile,
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
  let(:carrier_profile){ double("CarrierProfile", legal_name: "my legal name") }

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

  it "should have market" do
    expect(rendered).to match('Market')
    expect(rendered).to match('Employer Sponsored')
  end

  it "should not have cobra msg" do
    expect(rendered).not_to match("Your employer may charge an additional administration fee for your COBRA/Continuation coverage. If you have any questions, please direct them to the Employer")
  end
  
  
  context "will not a Pay Now options for plans other than Kaiser" do
    let!(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:dob) { Date.new(1985, 4, 10) }
    let(:person) { FactoryGirl.create(:person, :with_family,  :with_consumer_role, dob: dob) }
    let(:family) { person.primary_family }
    let(:household) { family.active_household }
    let(:individual_plans) { FactoryGirl.create_list(:plan, 5, :with_premium_tables, market: 'individual') }
    let(:plan) { individual_plans.first }
    let(:carrier_profile) { FactoryGirl.create(:carrier_profile) }

    let!(:hbx_enrollment) {
      FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, enrollment_members: family.family_members, household: household, plan: plan, effective_on: TimeKeeper.date_of_record.beginning_of_year, kind: 'individual')
    }

    it "should not have a Pay now button" do
      render file: "insured/plan_shoppings/receipt.html.erb"
      expect(rendered).to_not have_selector('btn-btn-default', text: /Pay Now/)
    end
    
    it "should not have Pay Now messaging" do
      render file: "insured/plan_shoppings/receipt.html.erb"
      expect(rendered).to_not have_content(/Select PAY NOW to make your first premium payment online/)
      expect(rendered).to_not have_content(/You only have the option to PAY NOW while you’re on this page/)
      expect(rendered).to_not have_content(/Select PAY NOW to make your first premium payment directly to Kaiser Permanente/)
    end
  end
  
  context "will have Pay Now options and messaging for Kaiser plans" do
    let!(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:dob) { Date.new(1985, 4, 10) }
    let(:person) { FactoryGirl.create(:person, :with_family,  :with_consumer_role, dob: dob) }
    let(:family) { person.primary_family }
    let(:household) { family.active_household }
    let(:individual_plans) { FactoryGirl.create_list(:plan, 5, :with_premium_tables, market: 'individual') }
    let(:carrier_profile) { FactoryGirl.create(:carrier_profile, legal_name:'Kaiser') }
    let(:plan) { FactoryGirl.create(:plan, carrier_profile:carrier_profile) }

    let!(:hbx_enrollment) {
      FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, enrollment_members: family.family_members, household: household, plan: plan, effective_on: TimeKeeper.date_of_record.beginning_of_year, kind: 'individual')
    }

    it "should have a Pay now button" do
      render file: "insured/plan_shoppings/receipt.html.erb"
      expect(rendered).to have_selector('button', text: /Pay Now/)
    end
    
    it "should have Pay Now messaging" do
      render file: "insured/plan_shoppings/receipt.html.erb"
      expect(rendered).to have_selector('strong', text: /You only have the option to PAY NOW while you’re on this page/)
      expect(rendered).to have_text(/Select PAY NOW to make your first premium payment directly to Kaiser Permanente/)
      expect(rendered).to have_text(/You only have the option to PAY NOW while you’re on this page/)
    end
  end

    
end
