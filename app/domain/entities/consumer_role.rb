# frozen_string_literal: true

module Entities
  class ConsumerRole < Dry::Struct
    transform_keys(&:to_sym)
    attribute :is_applying_coverage, Types::Strict::Bool.optional.meta(omittable: true)
    attribute :is_applicant, Types::Strict::Bool.optional.meta(omittable: true)
    attribute :is_state_resident, Types::Strict::Bool.optional.meta(omittable: true)
    attribute :lawful_presence_determination, Types::Strict::String.optional.meta(omittable: true)
    attribute :citizen_status, Types::Strict::String.optional.meta(omittable: true)
  end
end
