# frozen_string_literal: true

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
                                                                            unless: proc { |a| a.serves_entire_state? }

  scope :serving_entire_state, -> { where(serves_entire_state: true) }
  scope :for_issuer, ->(hios_ids) { where(issuer_hios_id: { "$in" => hios_ids }) }

  def self.service_areas_available_on(address, year)
    return([]) unless address.state.to_s.downcase == aca_state_abbreviation.to_s.downcase
    where({
            :active_year => year,
            "$or" => [
        {:serves_entire_state => true},
        {:service_area_zipcode => address.zip, county_name: ::Regexp.compile(::Regexp.escape(address.county).downcase, true)}
      ]
          })
  end
end
