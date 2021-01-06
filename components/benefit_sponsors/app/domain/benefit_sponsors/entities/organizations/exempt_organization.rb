# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Organizations
      # Entity to initialize while persisting ExemptOrganization record.
      class ExemptOrganization < Organization
        transform_keys(&:to_sym)

        attribute :fein,  Types::Strict::String.optional.meta(omittable: true)
      end
    end
  end
end