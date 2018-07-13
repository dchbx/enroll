class BenefitGroup

  include Mongoid::Document
  include Mongoid::Timestamps

  field :reference_plan_id, type: BSON::ObjectId
  field :plan_option_kind, type: String
  field :elected_plan_ids, type: Array, default: []

  embeds_many :relationship_benefits, cascade_callbacks: true

  def self.find(id)
  end

end
