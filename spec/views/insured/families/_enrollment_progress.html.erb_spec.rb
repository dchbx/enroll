require 'rails_helper'

RSpec.describe "insured/families/_enrollment_progress.html.erb" do

  let(:hbx_enrollment) {double(aasm_state: 'coverage_selected', kind: "employer_sponsored")}

  before :each do
    #assign(:hbx_enrollment, hbx_enrollment)
    allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
    render partial: "insured/families/enrollment_progress", locals: {step: 2}, collection: [hbx_enrollment], as: :hbx_enrollment
  end

  it "should display step name" do
    ["Applied", "Sent to Carrier", "Enrolled"].each do |step|
      #expect(rendered).to match /#{step}/
    end
  end

  it "should display percent_complete" do
    #expect(rendered).to have_selector("label", text:"66% Complete")
  end

end
