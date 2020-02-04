# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class Document < Dry::Struct
      transform_keys(&:to_sym)

      attribute :title,               Types::Strict::String
      attribute :creator,             Types::Strict::String
      attribute :subject,             Types::Strict::String
      attribute :description,         Types::Strict::String
      attribute :publisher,           Types::Strict::String
      attribute :contributor,         Types::Strict::String
      attribute :date,                Types::Duration
      attribute :type,                Types::Strict::String
      attribute :format,              Types::Strict::String
      attribute :identifier,          Types::Strict::String
      attribute :source,              Types::Strict::String
      attribute :language,            Types::Strict::String
      attribute :relation,            Types::Strict::String
      attribute :coverage,            Types::Strict::String
      attribute :rights,              Types::Strict::String
      attribute :tags,                Types::Strict::Array
      attribute :size,                Types::Strict::String
    end
  end
end