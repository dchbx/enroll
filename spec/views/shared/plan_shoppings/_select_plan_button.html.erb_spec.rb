require 'rails_helper'

RSpec.describe "shared/plan_shoppings/_select_plan_button.html.erb" do

  let(:person){ instance_double("Person") }
  let(:hbx_enrollment){ instance_double("HbxEnrollment")}
  let(:product_1){ instance_double("Product1", id: "test")}
  let(:product_2){ instance_double("Product2", id: "test")}
  let(:family){ instance_double("Family") }

  before :each do
    allow(person).to receive(:primary_family).and_return(family)
    allow(hbx_enrollment).to receive(:product).and_return(product_1)
    allow(family).to receive(:enrolled_hbx_enrollments).and_return([hbx_enrollment])
    assign :hbx_enrollment, hbx_enrollment
    assign :change_plan, "change_plan"
    assign :market_kind, "individual"
    assign :coverage_kind, "health"
    assign :enrollment_kind, ""
    assign :person, person
  end

  it "should show your current plan on plan comparison page" do
    render partial: "shared/plan_shoppings/select_plan_button", locals: {plan: product_1}
    expect(rendered).to match(/YOUR CURRENT PLAN/m)
  end

  it "should match dependent count" do
    allow(product_2).to receive(:id).and_return("test1")
    render partial: "shared/plan_shoppings/select_plan_button", locals: {plan: product_2}
    expect(rendered).to have_css("a.interaction-click-control-select-plan")
    expect(rendered).to match(/Select Plan/)
  end

end