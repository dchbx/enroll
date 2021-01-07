# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module Profiles
      class Parse
        include Dry::Monads[:result, :do]

        def call(params)
          parsed_params = yield parse(params)

          Success(parsed_params)
        end


       private

        def parse(params)
          attrs = {
            profile_type: params["profile_type"],
            staff_roles: build_staff_role_params(params["staff_roles_attributes"]["0"]),
            organization: build_org_params(params["organization"])
          }
          Success(attrs)
        end

        def build_staff_role_params(staff_role_attrs)
          attrs = {
            first_name: staff_role_attrs["first_name"],
            last_name: staff_role_attrs["last_name"],
            dob: Date.strptime(staff_role_attrs["dob"], "%m/%d/%Y"),
            email: staff_role_attrs["email"],
          }
          attrs.merge!(npn: staff_role_attrs["npn"]) if staff_role_attrs["npn"].present?
          attrs
        end

        def build_org_params(organization_params)
          profile_attrs = organization_params["profile_attributes"]
          office_location_attrs = profile_attrs["office_locations_attributes"]
          attrs = {
            entity_kind: organization_params["entity_kind"],
            legal_name: organization_params["legal_name"],
            dba: organization_params["dba"],
            profile: {
                        office_locations: nested_office_locations(office_location_attrs)
                      }
          }
          attrs[:profile].merge!(market_kind: profile_attrs["market_kind"]) if profile_attrs["market_kind"].present?
          attrs[:profile].merge!(languages_spoken: profile_attrs["languages_spoken"]) if profile_attrs["languages_spoken"].present?
          attrs[:profile].merge!(working_hours: profile_attrs["working_hours"]) if profile_attrs["working_hours"].present?
          attrs[:profile].merge!(accept_new_clients: profile_attrs["accept_new_clients"]) if profile_attrs["accept_new_clients"].present?
          attrs
        end

        def nested_office_locations(office_locations)
          office_location_array = []
          office_locations.each do |_key, value|
            symbolized_keys = value.deep_symbolize_keys!
            office_location_array << {address: symbolized_keys[:address_attributes], phone: symbolized_keys[:phone_attributes]}
          end
          office_location_array
        end
      end
    end
  end
end
