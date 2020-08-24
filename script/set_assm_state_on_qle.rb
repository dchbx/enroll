QualifyingLifeEventKind.where(is_active: true).each do |qle|
  visible = qle.is_self_attested ? true : false
  start_date = qle.start_on ? qle.start_on : qle.created_at
  qle.update_attributes(aasm_state: :active, is_visible: visible, start_on: start_date)
  qle.workflow_state_transitions << WorkflowStateTransition.new(from_state: :draft, to_state: :active, comment: 'manually updating aasm state as part of Manage SEP type feature.')
end