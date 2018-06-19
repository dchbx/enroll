module SponsoredBenefits
  module BenefitApplications
    class AcaShopDcBenefitApplication < BenefitApplication


      has_many :offered_benefit_products, class_name: "SponsoredBenefits::BenefitProducts::BenefitProduct"

    end
  end
end
