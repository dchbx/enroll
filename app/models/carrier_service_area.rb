class CarrierServiceArea
  include Mongoid::Document
  include Config::AcaModelConcern

  field :active_year, type: String
  field :issuer_hios_id, type: String
  field :service_area_id, type: String
  field :service_area_name, type: String
  field :serves_entire_state, type: Boolean, default: false
  field :county_name, type: String
  field :county_code, type: String
  field :state_code, type: String
  field :service_area_zipcode, type: String
  field :partial_county_justification, type: String
  validates_presence_of :service_area_id, :service_area_name, :serves_entire_state, :issuer_hios_id

  validates :county_name, :county_code, :state_code, :service_area_zipcode, presence: true,
    unless: Proc.new { |a| a.serves_entire_state? }

  scope :serving_entire_state, -> { where(serves_entire_state: true) }
  scope :for_issuer, -> (hios_ids) { where(issuer_hios_id: { "$in" => hios_ids }) }

  def self.service_areas_available_on(address, year)
    return([]) unless address.state.to_s.downcase == aca_state_abbreviation.to_s.downcase
    where({
      :active_year => year,
      "$or" => [
        {:serves_entire_state => true},
        {:service_area_zipcode => address.zip, county_name: Regexp.compile(Regexp.escape(address.county).downcase, true)}
      ]
    })
  end

  class << self

    def valid_for?(office_location:, carrier_profile:)
      issuers = for_issuer(carrier_profile.issuer_hios_ids)
      return true if issuers.serving_entire_state.any?

      return issuers.service_areas_for(office_location: office_location).any?
    end

    def valid_for_carrier_on(address:, carrier_profile:, year:)
      return([]) unless address.state.to_s.downcase == aca_state_abbreviation.to_s.downcase
      where({
        :active_year => year,
        issuer_hios_id: { "$in" => carrier_profile.issuer_hios_ids },
        "$or" => [
          {:serves_entire_state => true},
          {:service_area_zipcode => address.zip, county_name: Regexp.compile(Regexp.escape(address.county).downcase, true)}
        ]
      })
    end

    def service_areas_for(office_location:)
      address = office_location.address
      return([]) unless address.state.to_s.downcase == aca_state_abbreviation.to_s.downcase
      areas_valid_for_zip_code(zip_code: address.zip)
    end

    private

    def service_areas_for_carrier(carrier_profile)
      where(issuer_hios_id: carrier_profile.issuer_hios_ids)
    end

    def areas_valid_for_zip_code(zip_code:)
      where(service_area_zipcode: zip_code) + serving_entire_state
    end
  end
end
