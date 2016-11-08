require 'rails_helper'

RSpec.describe "shared/_signup_progress.html.haml" do
  before :each do
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
  end
  context "step 1" do
    before :each do
      render "shared/signup_progress"
    end

    it "shouldn't display the waive button" do
      expect(rendered).not_to have_selector('a', text: /Waive/)
    end
  end

  context "step 2" do
    before :each do
      render "shared/signup_progress", step: 2
    end

    it "shouldn't display the waive button" do
      expect(rendered).not_to have_selector('a', text: /Waive/)
    end
  end

  context "step 3" do
    before :each do
      render "shared/signup_progress", step: 3
    end

    it "shouldn't display the waive button" do
      expect(rendered).not_to have_selector('a', text: /Waive/)
    end
  end

  context "step 4" do
    before :each do
      render "shared/signup_progress", step: 4
    end

    it "shouldn't display the waive button" do
      expect(rendered).not_to have_selector('a', text: /Waive/)
    end
  end

  context "step 5" do
    let(:hbx_enrollment) {double(employee_role: double)}

    it "should display the waive button" do
      assign(:hbx_enrollment, hbx_enrollment)
      render "shared/signup_progress", step: 5
      expect(rendered).to have_selector('a', text: /Waive/)
    end

    it "should not display the waive button" do
      render "shared/signup_progress", step: 5
      expect(rendered).not_to have_selector('a', text: /Waive/)
    end
  end

  context "step 6" do
    let(:hbx_enrollment) { instance_double("HbxEnrollment", id: "hbx enrollment id", employee_role: double) }
    let(:plan) { instance_double("Plan", id: "plan id") }
    let(:family) { instance_double("Family", id: "family id") }
    before :each do
      assign(:enrollment, hbx_enrollment)
      assign(:enrollable, true)
      assign(:plan, plan)
      assign(:family, family)
    end

    it "should display the waive button" do
      allow(hbx_enrollment).to receive(:can_select_coverage?).and_return(true)
      render "shared/signup_progress", step: 6
      expect(rendered).to have_selector('a', text: /Waive/)
    end

    it "should not display the waive button" do
      allow(hbx_enrollment).to receive(:can_select_coverage?).and_return(true)
      allow(hbx_enrollment).to receive(:employee_role).and_return(nil)
      render "shared/signup_progress", step: 6
      expect(rendered).not_to have_selector('a', text: /Waive/)
    end

    context "when enrollment cannot be completed" do
      before :each do
        assign(:enrollable, false)
      end

      it "should disable the purchase button" do
        render "shared/signup_progress", step: 6
        expect(rendered).to match /<a[^>]*disabled="disabled"[^>]*>Confirm/
      end
    end
  end

  context "step 7" do
    before :each do
      render "shared/signup_progress", step: 7
    end

    it "shouldn't display the waive button" do
      expect(rendered).not_to have_selector('a', text: /Waive/)
    end
  end
end
