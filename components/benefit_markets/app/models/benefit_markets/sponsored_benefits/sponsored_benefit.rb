module BenefitMarkets
  module SponsoredBenefits
    class SponsoredBenefit
      include Mongoid::Document
      include Mongoid::Timestamps

      KINDS = [:health, :dental]

      field :hbx_id,      type: String
      field :title,       type: String
      field :description, type: String
      field :kind,        type: Symbol

      embeds_one  :product_package,       class_name: "BenefitMarkets::ProductPackages::ProductPackage"
      embeds_one  :contribution_model,    class_name: "BenefitMarkets::ContributionModels::ContributionModel"
      embeds_many :eligibility_policies,  class_name: "BenefitMarkets::Products::EligibilityPolicies::EligibilityPolicy"



    end
  end
end
