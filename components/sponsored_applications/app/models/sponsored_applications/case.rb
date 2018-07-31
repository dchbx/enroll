module SponsoredApplications
  class Case
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Userstamp
    include AASM

    field :case_id,     type: Integer, unique: true
    field :aasm_state,  type: String, default: "open"

    embeds_many :workflow_state_transitions, as: :transitional
    embeds_many :documents, as: :documentable


    aasm do
      state :open, initial: true
      state :closed


      event :close, :after => :record_transition do
        transitions from: :open, to: :closed
      end

    end


  private
    # Obtain next case number from global system counter
    def get_case_id
    end


    def record_transition
      self.workflow_state_transitions << WorkflowStateTransition.new(
        from_state: aasm.from_state,
        to_state: aasm.to_state
      )
    end
  end
end
