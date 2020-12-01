require 'rails_helper'

describe "shared/_signup_progress.html.erb" do
  before :each do
    allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
    allow(view).to receive(:policy_helper).and_return(double("Policy", can_access_pay_now?: true))
    render 'shared/signup_progress', locals: {step: '1'}
  end

  it "should have li option for Plan Selection" do
   expect(rendered).to have_selector("li", text: "Plan Selection")
  end
end
