module BenefitSponsors
  module Forms
    class EmailForm

      include ActiveModel::Validations
      include Virtus.model

      attribute :kind, String
      attribute :address, String

      # validates :address, :email => true, :allow_blank => false
      # validates_presence_of  :kind, message: "Choose a type"
      # validates_inclusion_of :kind, in: KINDS, message: "%{value} is not a valid email type"
    end
  end
end
