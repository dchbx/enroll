module SponsoredBenefits
  module BenefitSponsorships
    class BenefitPackage
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_application, class_name: "SponsoredBenefits::BenefitApplications::BenefitApplication"

      # The date range when this application is active
      field :effective_period,        type: Range

      # The date range when all members may enroll in benefit products
      field :open_enrollment_period,  type: Range

      # Length of time New Hire must wait before coverage effective date
      field :probation_period, type: Range

      field :benefit_rating_kind,     type: Symbol  # e.g. :list_bill, :composite

      embeds_many :benefit_products


    end
  end
end
