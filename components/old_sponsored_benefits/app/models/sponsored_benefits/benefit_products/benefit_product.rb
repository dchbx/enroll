module SponsoredBenefits
  module BenefitProducts
    class BenefitProduct
      include Mongoid::Document
      include Mongoid::Timestamps

      BENEFIT_PRODUCT_KINDS = [:health, :dental]

      has_and_belongs_to_many :benefit_market_service_periods, class_name: "SponsoredBenefits::BenefitMarketservicePeriod"

      field :issuer_profile_id, type: BSON::ObjectId
      field :benefit_product_kind, type: Symbol
      field :benefit_market_service_period_id, type: BSON::ObjectId

      field :purchase_period          # => jan 1 - dec 31, 2018

      embeds_many :benefit_product_rates, class_name: "SponsoredBenefits::BenefitProducts::BenefitProductRate"

      validates_presence_of :issuer_profile_id, :benefit_product_kind, :purchase_period
      validates :benefit_product_kind,
        inclusion: { in: BENEFIT_PRODUCT_KINDS, message: "%{value} is not a valid benefit market" }

      index(issuer_profile_id: 1)
      index(:"purchase_period.max" =>  1, :"purchase_period.min" => 1)


      scope :by_issuer_profile,   ->(issuer_profile){where(:"issuer_profile._id" => issuer_profile._id)}
      scope :by_effective_date,   ->(effective_date = Timekeeper.DateOfRecord) {
                                                          where(
                                                            :"purchase_period.min" => {:$gte => effective_date}, 
                                                            :"purchase_period.max" => {:$lte => effective_date}
                                                            )
                                                          }


      def issuer_profile
        SponsoredBenefits::Organizations::IssuerProfile.find(issuer_profile_id)
      end

      def sponsor_eligibility_policies
      end

      def member_eligibility_policies
      end

      # builders: sponsor (rating area, sic), effective_date

      ## Dates

      ## Benefit Product rate period - BenefitProduct
      # DC & MA SHOP Health: Q1, Q2, Q3, Q4
      # DC Dental: annual
      # GIC Medicare: Jan-June, July-Dec
      # DC & MA IVL: annual



      # Effective dates during which sponsor may purchase this product at this price
      ## DC SHOP Health   - annual product changes & quarterly rate changes
      ## CCA SHOP Health  - annual product changes & quarterly rate changes
      ## DC IVL Health    - annual product & rate changes
      ## Medicare         - annual product & semiannual rate changes

      field :product_purchase_period, type: Range
      has_many :rate_tables

    end
  end
end
