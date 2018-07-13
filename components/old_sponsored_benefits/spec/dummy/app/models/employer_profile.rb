class EmployerProfile

  include Mongoid::Document
  include Mongoid::Timestamps

  field :entity_kind, type: String
  field :sic_code, type: String

  embeds_many :plan_years, cascade_callbacks: true, validate: true
      
  def self.find(id)
  end

  def active_plan_year
  end
end
