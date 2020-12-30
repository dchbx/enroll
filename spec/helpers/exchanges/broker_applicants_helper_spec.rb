require "rails_helper"

RSpec.describe Exchanges::BrokerApplicantsHelper, dbclean: :after_each, :type => :helper do

  context "sort_by_latest_transition_time" do
    let(:person1) {FactoryBot.create(:person, :with_broker_role)}
    let(:person2) {FactoryBot.create(:person, :with_broker_role)}
    let(:person3) {FactoryBot.create(:person, :with_broker_role)}
    let(:people) {Person.exists(broker_role: true)}

    it "returns people array sorted by broker_role.latest_transition_time" do
      person1.broker_role.workflow_state_transitions.first.update_attributes(created_at: TimeKeeper.datetime_of_record - 6.days)
      person2.broker_role.workflow_state_transitions.first.update_attributes(created_at: TimeKeeper.datetime_of_record - 1.days)
      person3.broker_role.workflow_state_transitions.first.update_attributes(created_at: TimeKeeper.datetime_of_record - 2.days)
      expect(helper.sort_by_latest_transition_time(people).to_a).to eq([person2, person3, person1])
    end
  end
end
