# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class Document < Dry::Struct
      transform_keys(&:to_sym)

      attribute :title,               Types::Strict::String
      attribute :creator,             Types::Strict::String
      attribute :subject,             Types::String.optional.meta(omittable: true)
      attribute :description,         Types::String.optional.meta(omittable: true)
      attribute :publisher,           Types::Strict::String
      attribute :contributor,         Types::String.optional.meta(omittable: true)
      attribute :date,                Types::Date.optional.meta(omittable: true)
      attribute :type,                Types::Strict::String
      attribute :format,              Types::Strict::String
      attribute :identifier,          Types::String.optional.meta(omittable: true)
      attribute :source,              Types::Strict::String
      attribute :language,            Types::Strict::String
      attribute :relation,            Types::String.optional.meta(omittable: true)
      attribute :coverage,            Types::String.optional.meta(omittable: true)
      attribute :rights,              Types::String.optional.meta(omittable: true)
      attribute :tags,                Types::Array.optional.meta(omittable: true)
      attribute :size,                Types::String.optional.meta(omittable: true)
    end
  end
end