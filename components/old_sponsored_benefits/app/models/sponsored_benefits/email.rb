module SponsoredBenefits
  class Email
    include Mongoid::Document
    include Mongoid::Timestamps

    include Validations::Email

    embedded_in :person
    embedded_in :office_location
    embedded_in :census_member, class_name: "CensusMember"

    KINDS = %W(home work)

    field :kind, type: String
    field :address, type: String

    validates :address, presence: true, unless: :plan_design_model?
    validates :kind, presence: true, unless: :plan_design_model?
    validates_inclusion_of :kind, in: KINDS, message: "%{value} is not a valid email type", allow_blank: true

    def plan_design_model?
      _parent.is_a?(SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee) 
    end

    def blank?
      address.blank?
    end

    def match(another_email)
      return false if another_email.nil?
      attrs_to_match = [:kind, :address]
      attrs_to_match.all? { |attr| attribute_matches?(attr, another_email) }
    end

    def attribute_matches?(attribute, other)
      self[attribute] == other[attribute]
    end
  end
end
