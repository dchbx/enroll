# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Organizations
      # Entity to initialize while persisting ExemptOrganization record.
      class ExemptOrganization < Organization
        transform_keys(&:to_sym)

        attribute :profiles,  Types::Array.of(BenefitSponsors::Entities::Profiles::Profile)
      end
    end
  end
end