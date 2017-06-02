require "rails_helper"

RSpec.describe "insured/families/purchase.html.erb" do

  let(:employee_role){FactoryGirl.create(:employee_role)}
  let(:plan){FactoryGirl.create(:plan)}
  let(:benefit_group){ FactoryGirl.build(:benefit_group) }
  let(:hbx_enrollment){ HbxEnrollment.new(benefit_group: benefit_group, employee_role: employee_role, effective_on: 1.month.ago.to_date, updated_at: DateTime.now  ) }
  let(:person) { FactoryGirl.create(:person)}
  context "purchase" do
    before :each do
      @person = employee_role.person
      @plan = plan
      @enrollment = hbx_enrollment
      @benefit_group = benefit_group
      @reference_plan = @benefit_group.reference_plan
      @plan = PlanCostDecorator.new(@plan, @enrollment, @benefit_group, @reference_plan)
      allow(person).to receive(:consumer_role).and_return(false)
      @person = person
      render :template => "insured/families/purchase.html.erb"
    end

    it 'should display the correct plan selection text' do
      expect(rendered).to have_selector('h1', text: 'Confirm Your Plan Selection')
      expect(rendered).to have_selector('p', text: 'Your current plan selection is displayed below. Click the back button if you want to change your selection. Click Purchase button to complete your enrollment.')
      expect(rendered).to have_selector('p', text: 'Your enrollment is not complete until you purchase your plan selection below.')

    end

    it "should display the confirm button" do
      expect(rendered).to have_selector('a', text: 'Confirm')
      expect(rendered).not_to have_selector('a', text: 'Terminate Plan')
    end
  end

  context "terminate" do
    before :each do
      @person = employee_role.person
      @plan = plan
      @enrollment = hbx_enrollment
      @benefit_group = benefit_group
      @reference_plan = @benefit_group.reference_plan
      @plan = PlanCostDecorator.new(@plan, @enrollment, @benefit_group, @reference_plan)
      assign :terminate, 'terminate'
      render :template => "insured/families/purchase.html.erb"
    end

    it "should display the terminate button" do
      expect(rendered).to have_selector('a', text: 'Terminate Plan')
      expect(rendered).not_to have_selector('a', text: 'Purchase')
      expect(rendered).not_to have_selector('a', text: 'Confirm')
    end

    it "should display the terminate message" do
      expect(rendered).to have_selector('p', text: 'You will remain enrolled in coverage until you terminate your plan selection below.')
      expect(rendered).to have_selector('p', text: 'Click Terminate Plan button to complete your termination from coverage.')
    end
  end
end
