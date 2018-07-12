require 'rails_helper'

RSpec.describe "insured/families/_horizontal_status.html.erb" do
  it "should display the horizontal status bar with step value 2" do
    render "insured/families/horizontal_status", step: 2
    expect(rendered).to have_selector("strong", text: "Compare Plans And Choose")
    expect(rendered).to have_selector("span", text: "Enroll")
  end
end
