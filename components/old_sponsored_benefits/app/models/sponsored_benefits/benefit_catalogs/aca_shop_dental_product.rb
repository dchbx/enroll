module SponsoredBenefits
  module BenefitCatalogs
    class AcaShopDentalProduct < Product
      include Mongoid::Document
      include Mongoid::Timestamps


      # for dental plans only, metal level -> high/low values
      field :dental_level, type: String

    end
  end
end
