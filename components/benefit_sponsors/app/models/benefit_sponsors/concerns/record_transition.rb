module BenefitSponsors
  module Concerns::RecordTransition 
    extend ActiveSupport::Concern

    included do
      include AASM
      embeds_many :workflow_state_transitions, as: :transitional
      aasm do
        after_all_transitions :record_transition
      end
    end

    def record_transition
      workflow_state_transitions << WorkflowStateTransition.new({
        from_state: aasm.from_state, 
        to_state: aasm.to_state, 
        event: aasm.current_event
        })
    end
  end
end


  