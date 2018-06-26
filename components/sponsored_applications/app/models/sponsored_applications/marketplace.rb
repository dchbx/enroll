module SponsoredApplications
  class Marketplace
    include Mongoid::Document
    include Mongoid::Timestamps

    PRODUCT_KINDS         = [:health, :dental]
    SERVICE_MARKET_KINDS  = [:aca_shop, :employer_sponsored]

    field :title,                   type: String
    field :site_id,                 type: Symbol
    field :service_market_kind,     type: Symbol
    field :benefit_coverage_period, type: Range
    field :open_enrollment_period,  type: Range

    has_many :geographic_rating_areas
    has_many :issuers

    def issuers(effective_date)
    end

    def unique_benefit_product_kinds(effective_date)
    end

    def issuers_by_benefit_product_kind(product_kind, effective_date)
    end

    def benefit_sponsorships(effective_date)
    end

    def open_enrollment_begin_on
      open_enrollment_period.begin
    end

    def open_enrollment_end_on
      open_enrollment_period.end
    end


  end


  ## GIC
  # Open Enrollment
  #   Annual
  # Life Insurance
  #   
  # Medicare
  #   Special Enrollment - monthly
  #   Age 65
  #   Rate updates - every 6 months

end
