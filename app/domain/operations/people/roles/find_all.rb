# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    module Roles
      # Find all operation is to find all the available roles for the given user.
      # This will return an entity, which we use in our ERB files.
      class FindAll
        include Dry::Monads[:result, :do]


        def call(params)
          person_values = yield validate(params)
          person = yield fetch_person(person_values[:id])
          entity = yield fetch_available_roles(person)

          Success(entity)
        end

        private

        def validate(params)
          return Failure('Missing Key') unless params.key?(:id)

          Success(params)
        end

        def fetch_person(person_id)
          person = Person.where(id: person_id).first

          if person
            Success(person)
          else
            Failure({:message => ['Person not found']})
          end
        end

        def fetch_available_roles(person)
          roles = []
          roles << fetch_hbx_admin_details(person)
          roles << fetch_consumer_details(person)
          roles << fetch_resident_details(person)
          person.employee_roles.each do |ee_role|
            roles << fetch_employee_details(ee_role)
          end

          person.employer_staff_roles.each do |er_staff_role|
            roles << fetch_employer_staff_details(er_staff_role)
          end

          person.broker_agency_staff_roles.each do |br_staff_role|
            roles << fetch_broker_staff_details(br_staff_role)
          end

          person.general_agency_staff_roles.each do |ga_staff_role|
            roles << fetch_ga_staff_details(ga_staff_role)
          end

          entity = Entities::People::Roles::Account.new({roles: roles.compact})
          Success(entity)
        end

        def role_params(name, link, kind, created_at, status)
          {
            name: name,
            link: link,
            kind: kind,
            date: created_at,
            status: status,
            description: get_role_desc(kind.downcase)
          }
        end

        def get_role_desc(kind)
          if ['consumer', 'resident', 'employee'].include?(kind)
            'My Insurance Coverage'
          elsif kind == 'employer staff'
            "Point Of Contact - #{kind.humanize}"
          else
            kind.humanize
          end
        end

        def fetch_hbx_admin_details(person)
          return unless person.hbx_staff_role.present?

          role_params(person.full_name, "/exchanges/hbx_profiles", person.hbx_staff_role.subrole.split('_').join(" "), person.hbx_staff_role.created_at.to_date, :active)
        end

        def fetch_consumer_details(person)
          return unless person.is_consumer_role_active?

          link = person.consumer_role.bookmark_url

          role_params('My Coverage', link, "consumer", person.consumer_role.created_at.to_date, :active)
        end

        def fetch_resident_details(person)
          return unless person.is_resident_role_active?

          link = person.resident_role.bookmark_url

          role_params('My Coverage', link, "resident", person.resident_role.created_at.to_date, :active)
        end

        def fetch_employee_details(ee_role)
          link = ee_role.is_active? ? "/families/home" : nil
          created_at = ee_role.created_at.to_date
          status = ee_role.is_active? ? :active : :inactive
          role_params('My Coverage', link, "Employee", created_at, status)
        end

        def fetch_employer_staff_details(er_role)
          status = fetch_status(er_role.aasm_state)
          link = er_role.fetch_redirection_link
          created_at = er_role.created_at.to_date
          name = er_role.profile.legal_name
          role_params(name, link, "Employer Staff", created_at, status)
        end

        def fetch_broker_staff_details(broker_staff_role)
          profile = broker_staff_role.broker_agency_profile
          status = fetch_status(broker_staff_role.aasm_state)
          link = broker_staff_role.fetch_redirection_link
          created_at = broker_staff_role.created_at.present? ? broker_staff_role.created_at.to_date : nil
          name = profile.legal_name
          role_params(name, link, "Broker Staff", created_at, status)
        end

        def fetch_ga_staff_details(ga_staff_role)
          profile = ga_staff_role.general_agency_profile
          status = fetch_status(ga_staff_role.aasm_state)
          link = ga_staff_role.fetch_redirection_link
          created_at = ga_staff_role.created_at.present? ? ga_staff_role.created_at.to_date : nil
          name = profile.legal_name
          role_params(name, link, "GA Staff", created_at, status)
        end

        def fetch_status(aasm_state)
          case aasm_state.to_sym
          when :is_active, :active
            :active
          when :is_applicant, :general_agency_pending, :broker_agency_pending, :applicant
            :pending
          when :is_closed, :general_agency_terminated, :broker_agency_terminated, :general_agency_declined, :denied, :decertified
            :inactive
          end
        end
      end
    end
  end
end