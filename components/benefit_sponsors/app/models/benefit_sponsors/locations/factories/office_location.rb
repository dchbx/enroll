module BenefitSponsors
  module Locations
    module Factories
      class OfficeLocation
        def self.call(is_primary:, phone_attributes:, address_attributes:)
          phone = BenefitSponsors::Locations::Phone.new phone_attributes.slice(:kind, :area_code, :number, :extension)
          address = BenefitSponsors::Locations::Address.new address_attributes.slice(:kind, :address_1, :address_2, :city, :state, :zip)
          BenefitSponsors::Locations::OfficeLocation.new is_primary: is_primary, phone: phone, address: address
        end
      end
    end
  end
end
