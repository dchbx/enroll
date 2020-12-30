# frozen_string_literal: true

module Entities
  module SecureMessages
    class Message < Dry::Struct
      transform_keys(&:to_sym)

      attribute :subject,                Types::Strict::String
      attribute :body,                   Types::Strict::String
      attribute :from,                   Types::Strict::String
    end
  end
end