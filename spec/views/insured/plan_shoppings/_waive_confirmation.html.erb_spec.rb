# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "insured/plan_shoppings/_waive_confirmation.html.erb" do
  context "when not waivable" do
    before :each do
      assign(:waivable, false)
      allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
      render "insured/plan_shoppings/waive_confirmation"
    end

    it "should not display the waive button" do
      expect(rendered).not_to have_selector('a', text: /Waive/)
    end

    it "should display the reason coverage cannot be waived" do
      expect(rendered).to have_selector('h4', text: /Unable to Waive Coverage/)
    end
  end

  context "when waivable" do
    before :each do
      assign(:waivable, true)
      allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
      render "insured/plan_shoppings/waive_confirmation", enrollment: instance_double("HbxEnrollment", id: "enrollment_id")
    end

    it "should prompt for the waiver reason" do
      expect(rendered).to have_selector('h4', text: /Select Waive Reason/)
    end

    it "should have waiver reason options" do
      HbxEnrollment::WAIVER_REASONS.each do |w_reason|
        expect(rendered).to have_selector(:option, text: w_reason)
      end
    end

    it "should have disabled submit" do
      expect(rendered).to have_selector("input[disabled=disabled]", count: 1)
      expect(rendered).to have_selector("input[value='Submit']", count: 1)
    end
  end

  context "when coverage_kind is dental" do
    before :each do
      assign(:waivable, true)
      assign(:mc_coverage_kind, 'dental')
      allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
      render "insured/plan_shoppings/waive_confirmation", enrollment: instance_double("HbxEnrollment", id: "enrollment_id")
    end

    it "should display confirm waive" do
      expect(rendered).to have_content("Confirm Waive")
    end

    it "should not show waiver reason field" do
      expect(rendered).not_to have_content("Waiver Reason")
    end

    it "should show Confirm button rather than Submit" do
      expect(rendered).to have_content("Confirm")
      expect(rendered).not_to have_content("Submit")
    end
  end
end
