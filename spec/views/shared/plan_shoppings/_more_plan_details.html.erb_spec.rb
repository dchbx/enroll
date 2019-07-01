require 'rails_helper'

RSpec.describe "shared/plan_shoppings/_more_plan_details.html.erb" do
  let(:person) { FactoryBot.create(:person) }
  let(:person_two) { FactoryBot.create(:person, first_name: 'iajsdias') }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
  let(:household) { FactoryBot.create(:household, family: family) }
  let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, household: household, family: family) }
  let(:hbx_enrollment_member_one) { double("hbx_enrollment_member") }
  let(:hbx_enrollment_member_two) { double("hbx_enrollment_member") }
  let(:mock_group){double("membergroup", count: 4)}

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
    assign :member_groups, mock_group
  end

  # it "should match dependent count" do
  #   render "shared/plan_shoppings/more_plan_details"
  #   expect(rendered).to match /.*#{hbx_enrollment.humanized_dependent_summary} dependent*/m
  # end

  context "with a primary subscriber and one dependent" do
    before :each do
      allow(hbx_enrollment_member_one).to receive(:person).and_return(person)
      allow(hbx_enrollment_member_two).to receive(:person).and_return(person_two)
      allow(hbx_enrollment_member_one).to receive(:is_subscriber).and_return(true)
      allow(hbx_enrollment_member_two).to receive(:is_subscriber).and_return(false)
      allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return([hbx_enrollment_member_one, hbx_enrollment_member_two ])
      render "shared/plan_shoppings/more_plan_details", person: person
    end

    it "should match person full name" do
      expect(rendered).to match /#{person.full_name}/i
    end

    it "should match dependents full name" do
      expect(rendered).to match /#{person_two.full_name}/i
    end
  end

  context "with no primary subscriber and one dependent" do
    before :each do
      allow(hbx_enrollment_member_two).to receive(:person).and_return(person_two)
      allow(hbx_enrollment_member_two).to receive(:is_subscriber).and_return(false)
      allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return([hbx_enrollment_member_two])
      render "shared/plan_shoppings/more_plan_details", person: person
    end

    it "should match dependent count" do
      expect(rendered).to match /#{person_two.full_name}/i
    end
  end

end
