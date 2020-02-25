# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class Organization < Dry::Struct
      transform_keys(&:to_sym)

      attribute :hbx_id,                Types::Strict::String
      attribute :home_page,             Types::Strict::String
      attribute :legal_name,            Types::Strict::String
      attribute :dba,                   Types::Strict::String
      attribute :entity_kind,           Types::Strict::Symbol
      attribute :fein,                  Types::Strict::String
      attribute :site_id,               Types::Bson
    end
  end
end