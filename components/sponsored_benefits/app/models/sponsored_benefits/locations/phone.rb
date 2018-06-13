module SponsoredBenefits
  module Locations
    class Phone
    	include Mongoid::Document
      include Mongoid::Timestamps
      include SponsoredBenefits::Concerns::Phone
    end
  end
end