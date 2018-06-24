module Exchanges::BrokerApplicantsHelper
  def sort_by_latest_transition_time(broker_applicants)
    broker_applicants.sort({"broker_role.workflow_state_transitions.created_at": -1})
  end
end