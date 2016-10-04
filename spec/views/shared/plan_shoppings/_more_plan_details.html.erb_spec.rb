require 'rails_helper'

RSpec.describe "shared/plan_shoppings/_more_plan_details.html.erb" do
  let(:person) {FactoryGirl.create(:person)}
  let(:primary_family_member) { FamilyMember.new(:is_active => true, :is_primary_applicant => true,  :person => person) }
  let(:dependent_family_member) { FamilyMember.new(:is_active => true, :person => person) }
  let(:family) { Family.new(family_members: [dependent_family_member, primary_family_member]) }
  let(:household) { FactoryGirl.create(:household, family: family) }
  let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: household) }

  let(:plan){
    instance_double(
      "Plan"
      )
  }

  let(:plan_count){
    [plan, plan, plan, plan]
  }

  before :each do
    allow(hbx_enrollment).to receive(:humanized_dependent_summary).and_return(2)
    allow(person).to receive(:has_consumer_role?).and_return(false)
    assign :hbx_enrollment, hbx_enrollment
    assign :plans, plan_count
  end

  it "should match dependent count" do
    render "shared/plan_shoppings/more_plan_details"
    expect(rendered).to match /.*#{family.dependents.size} dependent*/m
  end

  context "with a primary subscriber and one dependent" do
    before :each do
      render "shared/plan_shoppings/more_plan_details", person: person
    end

    it "should match person full name" do
      expect(rendered).to match /#{family.primary_applicant.person.full_name}/i
    end

    it "should match dependents full name" do
      expect(rendered).to match /#{family.dependents.first.person.full_name}/i
    end
  end

end
