class BenefitGroupAssignment
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :census_employee

  field :benefit_group_id, type: BSON::ObjectId
  field :benefit_package_id, type: BSON::ObjectId # Engine Benefit Package

  # Represents the most recent completed enrollment
  field :hbx_enrollment_id, type: BSON::ObjectId

  field :start_on, type: Date
  field :end_on, type: Date
  field :coverage_end_on, type: Date
  field :aasm_state, type: String, default: "initialized"
  field :is_active, type: Boolean, default: true
  field :activated_at, type: DateTime


  def benefit_group=(benefit_package)
    self.benefit_group_id = benefit_package.id
  end

  aasm do
    state :initialized, initial: true
    state :coverage_selected
    state :coverage_waived
    state :coverage_terminated
    state :coverage_void
    state :coverage_renewing
    state :coverage_expired

  end
end
