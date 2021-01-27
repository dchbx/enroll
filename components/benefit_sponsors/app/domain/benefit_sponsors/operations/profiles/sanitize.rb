# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module Profiles
      #This operation is to construct a hash
      # with all the required params that are needed
      # for creation of organization
      class Sanitize
        include Dry::Monads[:result, :do]

        def call(params)
          sanitized_params = yield parse(params.deep_symbolize_keys!)

          Success(sanitized_params)
        end

        private

        def parse(params)
          attrs = {
            profile_type: params[:profile_type],
            staff_roles: build_staff_role_params(params[:staff_roles_attributes][:'0']),
            organization: build_org_params(params[:organization])
          }
          Success(attrs)
        end

        def build_staff_role_params(staff_role_attrs)
          attrs = {
            first_name: staff_role_attrs[:first_name],
            last_name: staff_role_attrs[:last_name],
            dob: Date.strptime(staff_role_attrs[:dob], '%m/%d/%Y'),
            email: staff_role_attrs[:email]
          }
          attrs.merge!(npn: staff_role_attrs[:npn]) if staff_role_attrs[:npn].present?
          attrs.merge!(coverage_record: coverage_record_attributes(staff_role_attrs[:coverage_record])) if staff_role_attrs[:coverage_record].present?
          attrs
        end

        def coverage_record_attributes(coverage_record_params)
          attrs = {
            is_applying_coverage: coverage_record_params[:is_applying_coverage],
            address: coverage_record_params[:address].to_h.deep_symbolize_keys!,
            email: coverage_record_params[:email].to_h.deep_symbolize_keys!
          }
          if coverage_record_params[:is_applying_coverage] == 'true'
            attrs.merge!(ssn: coverage_record_params[:ssn],
                         gender: coverage_record_params[:gender],
                         hired_on: Date.strptime(coverage_record_params[:hired_on], '%Y-%m-%d'))
          end
          attrs
        end

        def build_org_params(organization_params)
          profile_attrs = organization_params[:profile]
          office_location_attrs = profile_attrs[:office_locations_attributes]
          attrs = {
            entity_kind: organization_params[:entity_kind],
            legal_name: organization_params[:legal_name],
            dba: organization_params[:dba],
            fein: organization_params[:fein],
            profile: { office_locations: nested_office_locations(office_location_attrs) }
          }
          attrs[:profile].merge!(market_kind: profile_attrs[:market_kind]) if profile_attrs[:market_kind].present?
          attrs[:profile].merge!(languages_spoken: profile_attrs[:languages_spoken]) if profile_attrs[:languages_spoken].present?
          attrs[:profile].merge!(working_hours: profile_attrs[:working_hours]) if profile_attrs[:working_hours].present?
          attrs[:profile].merge!(accept_new_clients: profile_attrs[:accept_new_clients]) if profile_attrs[:accept_new_clients].present?
          attrs[:profile].merge!(contact_method: profile_attrs[:contact_method]) if profile_attrs[:contact_method].present?
          attrs
        end

        def nested_office_locations(office_locations)
          office_location_array = []
          office_locations.each do |_key, value|
            symbolized_keys = value.to_h.deep_symbolize_keys!
            office_location_array << {address: symbolized_keys[:address], phone: symbolized_keys[:phone]}
          end
          office_location_array
        end
      end
    end
  end
end
