# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class ExemptOrganization < Dry::Struct
      transform_keys(&:to_sym)

      attribute :hbx_id,                Types::Strict::String.optional.meta(omittable: true)
      attribute :home_page,             Types::String.optional.meta(omittable: true)
      attribute :legal_name,            Types::Strict::String
      attribute :dba,                   Types::String.optional.meta(omittable: true)
      attribute :entity_kind,           Types::Strict::Symbol.optional.meta(omittable: true)
      attribute :site_id,               Types::Bson
      attribute :site_owner_id,         Types::Bson.optional.meta(omittable: true)
      attribute :agency_id,             Types::Strict::Symbol.optional.meta(omittable: true)
      attribute :profiles,              Types::Array.of(BenefitSponsors::Entities::Profiles::Profile)
    end
  end
end