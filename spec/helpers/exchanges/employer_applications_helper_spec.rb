require "rails_helper"

RSpec.describe Exchanges::EmployerApplicationsHelper, :type => :helper do

  context "can_terminate_application" do

    let(:plan_year) {FactoryGirl.create(:plan_year)}
    valid_states_for_termination = ["active", "suspended", "expired"]

    valid_states_for_termination.each do |aasm_state|

      it "should return true" do
        plan_year.update_attributes!(:aasm_state => aasm_state)
        expect(helper.can_terminate_application?(plan_year)).to be_truthy
      end
    end

  end

  context "can_cancel_application" do

    let(:plan_year) {FactoryGirl.create(:plan_year)}
    valid_states_for_canceling = PlanYear::PUBLISHED + PlanYear::RENEWING + PlanYear::INITIAL_ENROLLING_STATE + ["renewing_application_ineligible", "application_ineligible", "draft"]

    valid_states_for_canceling.each do |aasm_state|

      it "should return true" do
        plan_year.update_attributes!(:aasm_state => aasm_state)
        expect(helper.can_cancel_application?(plan_year)).to be_truthy
      end
    end

  end
end
