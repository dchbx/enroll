# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  class UpdateDobSsn
    send(:include, Dry::Monads[:result, :do])

    def call(person_id:, params:, info_changed:, dc_status:, current_user:, ssn_require:)
      person = yield fetch_person(person_id)
      yield validate_if_person_can_update(person)
      update_person(person, params, info_changed, dc_status, current_user, ssn_require)
    end

    private

    def fetch_person(person_id)
      person = ::Person.where(_id: person_id).first
      person ? Success(person) : Failure([{person: ['Person not found']}, nil])
    end

    def validate_if_person_can_update(person)
      if person&.consumer_role&.vlp_documents.present?
        result = ::Operations::ValidateVlpDocument.new.call(person_id: person.id)
        result.failure? ? Failure([{person: [result.failure]}, nil]) : Success(true)
      else
        Success(true)
      end
    end

    def update_person(person, params, info_changed, dc_status, current_user, ssn_require)
      person.dob = Date.strptime(params[:jq_datepicker_ignore_person][:dob], '%m/%d/%Y').to_date
      if params[:person][:ssn].blank?
        if ssn_require
          dont_update_ssn = true
        else
          person.unset(:encrypted_ssn)
        end
      else
        person.ssn = params[:person][:ssn]
      end
      person.save!
      person.consumer_role.check_for_critical_changes(person.primary_family, info_changed: info_changed, no_dc_address: "false", dc_status: dc_status) if person.consumer_role && person.is_consumer_role_active?
      CensusEmployee.update_census_employee_records(person, current_user)
      Success([nil, dont_update_ssn])
    rescue StandardError => e
      error_on_save = person.errors.messages
      error_on_save[:census_employee] = [e.summary] if person.errors.messages.blank? && e.present?
      Failure([error_on_save, dont_update_ssn])
    end
  end
end
