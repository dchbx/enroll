module BenefitSponsors
  module Locations
    class OfficeLocation
      include Mongoid::Document

      embedded_in :profile, class_name: "BenefitSponsors::Organizations::Profile"

      field :is_primary, type: Boolean, default: true

      embeds_one :address, class_name:"BenefitSponsors::Locations::Address", cascade_callbacks: true, validate: true
      embeds_one :phone, class_name:"BenefitSponsors::Locations::Phone", cascade_callbacks: true, validate: true
    end
  end
end