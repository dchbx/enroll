require 'rails_helper'

RSpec.describe "products/qhp/summary.js.erb" do
 let(:benefit_group) { double("BenefitGroup") }
  before :each do
    assign(:benefit_group, benefit_group)
    allow(benefit_group).to receive(:sole_source?).and_return(true)
    stub_template "shared/_summary.html.erb" => ''
    render file: "products/qhp/summary.js.erb"
  end

  it "should call account-detail" do
    expect(rendered).to match /account-detail/
    expect(rendered).to match /all-plans/
    expect(rendered).to match /plan-summary/
  end

  it "should call scroll" do
    expect(rendered).to match /scroll/
  end
end
