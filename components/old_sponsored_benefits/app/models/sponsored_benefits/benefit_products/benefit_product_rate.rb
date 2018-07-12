module SponsoredBenefits
  module BenefitProducts
    class BenefitProductRate
    include Mongoid::Document
    include Mongoid::Timestamps

      field :rate_period, type: Range   # => jan 1 - march 31, 2018


    end
  end
end
