class PlanYear

  include Mongoid::Document
  include Mongoid::Timestamps

  field :start_on, type: Date
  field :end_on, type: Date

  field :open_enrollment_start_on, type: Date
  field :open_enrollment_end_on, type: Date

  embeds_many :benefit_groups, cascade_callbacks: true

end