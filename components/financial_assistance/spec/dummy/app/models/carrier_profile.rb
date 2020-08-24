# frozen_string_literal: true

class CarrierProfile
  include Mongoid::Document
  include Config::AcaModelConcern
  include Mongoid::Timestamps

  embedded_in :organization

  # temporary field for importing seed files
  field :hbx_carrier_id, type: Integer

  field :abbrev, type: String
  field :associated_carrier_profile_id, type: BSON::ObjectId

  field :ivl_health, type: Boolean
  field :ivl_dental, type: Boolean
  field :shop_health, type: Boolean
  field :shop_dental, type: Boolean

  field :issuer_hios_id, type: String
  field :issuer_state, type: String, default: "DC"
  field :market_coverage, type: String, default: "shop (small group)" # or individual
  field :dental_only_plan, type: Boolean, default: false
  field :offers_sole_source, type: Boolean, default: false
  field :issuer_hios_ids, type: Array, default: []


  delegate :hbx_id, to: :organization, allow_nil: true
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: false
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: false
  delegate :is_active, :is_active=, to: :organization, allow_nil: false
  delegate :updated_by, :updated_by=, to: :organization, allow_nil: false


  delegate :legal_name, :legal_name=, to: :organization, allow_nil: false

  def self.for_issuer_hios_id(issuer_id)
    Organization.where("carrier_profile.issuer_hios_ids" => issuer_id).map(&:carrier_profile)
  end

  class << self
    def find(id)
      organizations = Organization.where("carrier_profile._id" => BSON::ObjectId.from_string(id.to_s)).to_a
      !organizations.empty? ? organizations.first.carrier_profile : nil
    end

    def carrier_profile_service_area_pairs_for(employer_profile, start_on)
      hios_carrier_id_mapping = Organization.where("carrier_profile" => {"$exists" => true}).inject({}) do |acc, org|

        cp = org.carrier_profile

        cp.issuer_hios_ids.each do |ihid|
          acc[ihid] = cp.id
        end
        acc
      end
      employer_profile.service_areas_available_on(DateTime.new(start_on.to_i)).map do |service_area|
        [hios_carrier_id_mapping[service_area.issuer_hios_id], service_area.service_area_id]
      end.uniq
    end
  end
end
