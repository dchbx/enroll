module SponsoredBenefits
  module BenefitPackages
    class BenefitPackage
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_packageable, polymorphic: true

      # Length of time New Hire must wait before coverage effective date
      field :probationary_period

    end
  end
end
