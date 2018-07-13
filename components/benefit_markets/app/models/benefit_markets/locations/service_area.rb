module BenefitMarkets
  module Locations
    class ServiceArea
      include Mongoid::Document
      include Mongoid::Timestamps

      field :active_year, type: Integer
      field :issuer_provided_title, type: String
      field :issuer_provided_code, type: String
      field :issuer_profile_id, type: BSON::ObjectId

      # The list of county-zip pairs covered by this service area
      field :county_zip_ids, type: Array

      # This service area may cover entire state(s), if it does,
      # specify which here.
      field :covered_states, type: Array

      validates_presence_of :active_year, allow_blank: false
      validates_presence_of :issuer_provided_code, allow_nil: false
      validates_presence_of :issuer_profile_id, allow_nil: false
      validate :location_specified

      index({county_zip_ids: 1})
      index({covered_state_codes: 1})

      def location_specified
        if county_zip_ids.blank? && covered_states.blank?
          errors.add(:base, "a location covered by the service area must be specified")
        end
        true
      end

      def self.service_areas_for(address, during: TimeKeeper.date_of_record)
        county_name = address.county.blank? ? "" : address.county.titlecase
        zip_code = address.zip
        state_abbrev = address.state.blank? ? "" : address.state.upcase

        county_zip_ids = ::BenefitMarkets::Locations::CountyZip.where(
          :county_name => county_name,
          :zip => zip_code,
          :state => state_abbrev
        ).map(&:id).uniq

        service_areas = self.where(
          "active_year" => during.year,
          "$or" => [
            {"county_zip_ids" => { "$in" => county_zip_ids }},
            {"covered_states" =>  state_abbrev}
          ]
        )
        service_areas
      end
    end
  end
end
