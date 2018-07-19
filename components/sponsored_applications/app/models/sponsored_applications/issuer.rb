module SponsoredApplications
  class Issuer
    include Mongoid::Document

    has_many :benefit_products

    def benefit_products_by_effective_date(effective_date)
    end

  end
end
