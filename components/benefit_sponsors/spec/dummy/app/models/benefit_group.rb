class BenefitGroup

  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :description, type: String


  def self.find(id)
  end

end