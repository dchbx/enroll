QualifyingLifeEventKind.where(is_active: true).each do |qle|
  visible = qle.is_self_attested ? true : false
  qle.update_attributes(aasm_state: :active, is_visible: visible)
  qle.workflow_state_transitions << WorkflowStateTransition.new(from_state: :draft, to_state: :active, comment: 'manually updating aasm state as part of Manage SEP type feature.')
end