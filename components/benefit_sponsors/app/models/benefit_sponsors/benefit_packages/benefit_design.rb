module BenefitSponsors
  module BenefitPackages
    class BenefitDesign
      include Mongoid::Document
      include Mongoid::Timestamps
    
      embedded_in :benefit_package, class_name: "BenefitSponsors::BenefitSponsorships::BenefitPackage"

      PLAN_OPTION_KINDS = %w(single_plan single_carrier metal_level sole_source)

      field :benefit_kind, type: String # e.g. :health, :dental
      field :plan_option_kind, type: String
      field :reference_plan_id, type: String
      field :benefit_rating_kind,  type: Symbol  # e.g. :list_bill, :composite
          
      embeds_one :contribution_model

    end
  end
end
