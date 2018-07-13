module SponsoredBenefits
  module Locations
    class Address
      include Mongoid::Document
      include Mongoid::Timestamps
      include SponsoredBenefits::Concerns::Address

    end
  end
end
