# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Organizations
      # Entity to initialize while persisting GeneralOrganization record.
      class GeneralOrganization < Organization
        transform_keys(&:to_sym)

        attribute :fein,      Types::Strict::String
      end
    end
  end
end