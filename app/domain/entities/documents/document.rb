# frozen_string_literal: true

module Entities
  module Documents
    class Document < Dry::Struct
      transform_keys(&:to_sym)

      attribute :title,                Types::Strict::String
      attribute :creator,              Types::Strict::String
      attribute :subject,              Types::Strict::String
      attribute :doc_identifier,       Types::Strict::String
      attribute :format,               Types::Strict::String
    end
  end
end