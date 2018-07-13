module BenefitSponsors
  module CensusMembers

    ## Deprecated


    # class BenefitGroupAssignment
    #   include Mongoid::Document
    #   include Mongoid::Timestamps
    #   include AASM

    #   embedded_in :benefit_assignable, polymorphic: true

    #   field :benefit_group_id, type: BSON::ObjectId

    #   # Represents the most recent completed enrollment
    #   field :hbx_enrollment_id, type: BSON::ObjectId

    #   field :start_on, type: Date
    #   field :end_on, type: Date
    #   field :coverage_end_on, type: Date
    #   field :aasm_state, type: String, default: "initialized"
    #   field :is_active, type: Boolean, default: true
    #   field :activated_at, type: DateTime

    #   embeds_many :workflow_state_transitions, as: :transitional
    #   validates_presence_of :benefit_group_id, :start_on, :is_active


    #   def self.by_benefit_group_id(bg_id)
    #     census_employees = PlanDesignCensusEmployee.where({
    #       "benefit_group_assignments.benefit_group_id" => bg_id
    #       })
    #     census_employees.flat_map(&:benefit_group_assignments).select do |bga|
    #       bga.benefit_group_id == bg_id
    #     end
    #   end

    #   def benefit_group=(new_benefit_group)
    #     raise ArgumentError.new("expected BenefitGroup") unless new_benefit_group.is_a? BenefitGroup
    #     self.benefit_group_id = new_benefit_group._id
    #     @benefit_group = new_benefit_group
    #   end

    #   def benefit_group
    #     return @benefit_group if defined? @benefit_group
    #     return nil if benefit_group_id.blank?
    #     @benefit_group = BenefitGroup.find(self.benefit_group_id)
    #   end

    #   aasm do
    #     state :initialized, initial: true

    #   end

    #   def make_active
    #     census_employee.benefit_group_assignments.each do |bg_assignment|
    #       if bg_assignment.is_active? && bg_assignment.id != self.id
    #         bg_assignment.update_attributes(is_active: false, end_on: [start_on - 1.day, bg_assignment.start_on].max)
    #       end
    #     end

    #     update_attributes(is_active: true, activated_at: TimeKeeper.datetime_of_record) unless is_active?
    #   end

    #   private

    #   def record_transition
    #     self.workflow_state_transitions << WorkflowStateTransition.new(
    #       from_state: aasm.from_state,
    #       to_state: aasm.to_state
    #       )
    #   end
    # end
  end
end
