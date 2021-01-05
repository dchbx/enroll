# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Profiles
      class AgencyProfile < Profile
        transform_keys(&:to_sym)

        attribute :contact_method,                     Types::Strict::Symbol
        attribute :market_kind,                        Types::Strict::Symbol
        attribute :corporate_npn,                      Types::Strict::String
        attribute :languages_spoken,                   Types::Array.optional.meta(omittable: true)
        attribute :working_hours,                      Types::Strict::Bool.optional.meta(omittable: true)
        attribute :accept_new_clients,                 Types::Strict::Bool.optional.meta(omittable: true)
        attribute :home_page,                          Types::String.optional.optional.meta(omittable: true)
      end
    end
  end
end