# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class Document < Dry::Struct
      transform_keys(&:to_sym)

      attribute :title,               Types::Strict::String
      attribute :creator,             Types::Strict::String
      attribute :subject,             Types::String.optional
      attribute :description,         Types::String.optional
      attribute :publisher,           Types::Strict::String
      attribute :contributor,         Types::String.optional
      attribute :date,                Types::Date.optional
      attribute :type,                Types::Strict::String
      attribute :format,              Types::Strict::String
      attribute :identifier,          Types::String.optional
      attribute :source,              Types::Strict::String
      attribute :language,            Types::Strict::String
      attribute :relation,            Types::String.optional
      attribute :coverage,            Types::String.optional
      attribute :rights,              Types::String.optional
      attribute :tags,                Types::Array.optional
      attribute :size,                Types::String.optional
    end
  end
end