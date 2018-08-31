require "rails_helper"

RSpec.describe Exchanges::HbxProfilesHelper, :type => :helper do

  context "can_cancel_employer_plan_year?" do
    let(:valid_states) { ['published', 'enrolling', 'enrolled', 'active'] }
    let(:employer_profile) { FactoryGirl.create(:employer_with_planyear) }

    it "returns people array sorted by broker_role.latest_transition_time" do
      valid_states.each  do |state|
        employer_profile.plan_years.first.update_attribute(:aasm_state, state)
        expect(helper.can_cancel_employer_plan_year?(employer_profile)).to eq(true)
      end
    end
  end
end
