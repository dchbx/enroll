# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module Profiles
      class FindProfile
        include Dry::Monads[:result, :do]


        def call(params)
          person = yield fetch_person(params[:id]) if params[:person_id].present?
          profile = yield fetch_profile(params[:profile_id]) if params[:profile_id].present?
          params = yield build_profile_params(person, profile)
          entity = get_entity(params)

          Success(entity)
        end

        private

        def fetch_person(id)
          person = Person.where(id: id).first

         person ? Success(person) : Failure({:message => ['Person not found']})
        end

        def build_profile_params(person, profile)

          Success(
            {
              staff_roles: {
                first_name: person&.first_name,
                last_name: person&.last_name,
                dob: person&.dob,
                email: person&.work_email_or_best,
                area_code: person&.work_phone&.area_code,
                number: person&.work_phone&.number,
                npn: nil
              },
              organization: {
                legal_name: profile&.legal_name,
                dba: profile&.dba,
                fein: profile&.fein,
                entity_kind: profile&.entity_kind,
                profile: {
                  sic_code: nil,
                  market_kind: nil,
                  languages_spoken: nil,
                  working_hours: nil,
                  accept_new_clients: nil,
                  ach_account_number: nil,
                  ach_routing_number: nil,
                  ach_routing_number_confirmation: nil,
                  office_locations: {
                    address: {
                      kind: nil,
                      address_1: nil,
                      address_2: nil,
                      address_3: nil,
                      city: nil,
                      county: nil,
                      state: nil,
                      zip: nil,
                    },
                    phone: {
                      kind: 'work',
                      number: nil,
                      extension: nil
                    }
                  }
                }
              }
            })
        end

        def get_entity(params)
          Try do
            Success(Entities::Staff.new(params))
          end.or(Failure({:message => ['Invalid Params']}))
        end
      end
    end
  end
end
