class RenewalPlanMapping
  include Mongoid::Document
  include Mongoid::Timestamps

  field :start_on, type: Date
  field :end_on,   type: Date
  field :renewal_plan_id, type: BSON::ObjectId
  field :is_active, type: Boolean, default: true

  embedded_in :plan

  validates_presence_of :start_on, :end_on, :renewal_plan_id

  scope :by_date, ->(effective_date) { where({:start_on.lte => effective_date, :end_on.gte => effective_date, :is_active => true}) }


  def renewal_plan
    Plan.find(renewal_plan_id)
  end

end
