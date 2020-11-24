# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "ui-components/v1/modals/_waive_confirmation_while_shopping.html.slim" do
  context "when not waivable" do
    let(:person) { FactoryBot.create(:person) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:enrollment) { FactoryBot.create(:hbx_enrollment, family: family, coverage_kind: 'dental', kind: 'individual') }

    before :each do
      assign(:waivable, false)
      allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
      render "ui-components/v1/modals/waive_confirmation_during_shopping", enrollment: enrollment
    end

    it "should not display the waive button" do
      expect(rendered).not_to have_selector('a', text: /Waive/)
    end

    it "should display the reason coverage cannot be waived" do
      expect(rendered).to have_selector('h4', text: /Unable to Waive Coverage/)
    end
  end

  context "when waivable" do
    let(:person) { FactoryBot.create(:person) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:enrollment) { FactoryBot.create(:hbx_enrollment, family: family) }

    before :each do
      assign(:waivable, true)
      allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
      render "ui-components/v1/modals/waive_confirmation_during_shopping", enrollment: enrollment
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

    context "when coverage_kind is dental" do
      let(:person) { FactoryBot.create(:person) }
      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
      let(:enrollment) { FactoryBot.create(:hbx_enrollment, family: family, coverage_kind: 'dental') }

      before :each do
        assign(:mc_coverage_kind, 'dental')
        allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
        render "ui-components/v1/modals/waive_confirmation_during_shopping", enrollment: enrollment
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
end
