# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  class ImportFaaApplicants
    send(:include, Dry::Monads[:result, :do])

    PersonCandidate = Struct.new(:ssn, :dob)

    # @param [ Bson::ID ] application_id Application ID
    # @param [ Bson::ID ] family_id Family ID
    # @return [ Family ] family Family
    def call(application_id:, family_id:)
      application = yield find_application(application_id)
      family      = yield find_family(family_id)
      family      = yield validate(application, family)
      application_payload = yield get_application_payload(application)
      family, applicant_family_mapping = yield create_family_members(application_payload, family)
      _application = yield update_applicants(application, applicant_family_mapping)

      Success(family)
    end

    private

    def validate(application, family)
      errors = []
      errors << 'Application family not matching the family ID passed' unless application.family == family

      if errors.empty?
        Success(family)
      else
        Failure(errors)
      end
    end

    def find_application(application_id)
      application = FinancialAssistance::Application.find(application_id)

      Success(application)
    rescue Mongoid::Errors::DocumentNotFound
      Failure("Unable to find Application with ID #{application_id}.")
    end

    def find_family(family_id)
      family = Family.find(family_id)
      Success(family)
    rescue StandardError
      Failure("Unable to find Family with ID #{family_id}.")
    end

    def get_application_payload(application)
      FinancialAssistance::Operations::Application::Export.new.call(application: application)
    end

    def create_family_members(payload, family)
      applicant_id_mappings = {}

      payload[:applicants].each do |applicant|
        candidate = PersonCandidate.new(applicant[:ssn], applicant[:dob])

        if applicant[:family_member_id].present?
          applicant_id_mappings[applicant[:_id]] = {
            family_member_id: applicant[:family_member_id],
            person_hbx_id: applicant[:person_hbx_id]
          }
          # update
        else
          person = Person.match_existing_person(candidate)

          if person.blank?
            new_person_params = extract_person_params(applicant).merge(hbx_id: applicant[:person_hbx_id])
            person = Person.new(new_person_params)
            return false unless try_create_person(person)
          end

          family_member = family.relate_new_member(person, applicant[:relationship])
          family_member.family.build_consumer_role(family_member, extract_consumer_role_params(applicant)) if applicant[:is_consumer_role]

          %w[addresses emails phones].each do |assoc|
            create_or_update_associations(person, applicant, assoc)
          end

          family.save!
          family.primary_person.save!
          applicant_id_mappings[applicant[:_id]] = {
            family_member_id: family_member.id,
            person_hbx_id: person.hbx_id
          }
        end
      end

      Success([family, applicant_id_mappings])
    end

    def create_or_update_associations(person, applicant, assoc)
      records = applicant[assoc.to_sym]
      return if records.empty?

      records.each do |attrs|
        address_matched = person.send(assoc).detect{|adr| adr.kind == attrs[:kind] }
        if address_matched
          address_matched.update(attrs)
        else
          person.send(assoc).create(attrs)
        end
      end
    end

    def update_applicants(application, family_member_mapping)
      application.applicants.each do |applicant|
        next if applicant.family_member_id.present?
        applicant.family_member_id = family_member_mapping[applicant.id][:family_member_id]
        applicant.person_hbx_id = family_member_mapping[applicant.id][:person_hbx_id]
      end
      application.save!
      Success(application)
    end

    def extract_person_params(applicant)
      attributes = [
        :first_name,:last_name,:middle_name,:name_pfx,:name_sfx,:gender,:dob,
        :ssn,:no_ssn,:race,:ethnicity,:language_code,:is_incarcerated,:citizen_status,
        :tribal_id,:no_dc_address,:is_homeless,:is_temporarily_out_of_state
      ]

      applicant.slice(*attributes)
    end

    def extract_consumer_role_params(applicant)
      attributes = [:citizen_status, :vlp_document_id, :is_applying_coverage]
      applicant.slice(*attributes)
    end

    def try_create_person(person)
      person.save.tap do
        bubble_person_errors(person)
      end
    end

    def bubble_person_errors(person)
      self.errors.add(:ssn, person.errors[:ssn]) if person.errors.key?(:ssn)
    end
  end
end
