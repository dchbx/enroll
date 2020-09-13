# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    class AddFinancialAssistanceEligibility
      send(:include, Dry::Monads[:result, :do])

      def call(application:)

        parsed_object = yield fetch_parser_object(application)
        primary_family_member, dependents = yield fetch_primary_family_member_and_dependents(parsed_object)
        primary_person = yield fetch_person(primary_family_member)
        family = yield fetch_family(primary_person)
        active_household = yield fetch_active_household(family)
        household_from_payload = yield fetch_household_from_parsed_object(parsed_object)
        yield check_if_dependents_exist_in_ea(dependents)
        yield set_integrated_case_id(family, parsed_object)

        result = yield create_tax_households(active_household, parsed_object, primary_person, household_from_payload, application)

        Success(result)
      end


      private

      def fetch_parser_object(application)
        parser = Parsers::Xml::Cv::Haven::VerifiedFamilyParser.new
        Success(parser.parse(application.eligibility_response_payload))
      end

      def fetch_primary_family_member_and_dependents(parsed_object)
        family_member = parsed_object.family_members.detect {|fm| fm.person.hbx_id == parsed_object.primary_family_member_id}
        dependents = parsed_object.family_members.reject {|fm| fm.person.hbx_id == parsed_object.primary_family_member_id}
        Success([family_member,dependents])
      end

      def find_application(application_id)
        application = FinancialAssistance::Application.find(application_id)

        Success(application)
      rescue Mongoid::Errors::DocumentNotFound
        Failure("Unable to find Application with ID #{application_id}.")
      end

      def fetch_person(verified_family_member)
        ssn = verified_family_member.person_demographics.ssn
        ssn = '' if ssn == '999999999'
        dob = verified_family_member.person_demographics.birth_date
        last_name_regex = /^#{verified_family_member.person.name_last}$/i
        first_name_regex = /^#{verified_family_member.person.name_first}$/i
        person = if !ssn.blank?
                   Person.where({
                                  :encrypted_ssn => Person.encrypt_ssn(ssn),
                                  :dob => dob
                                }).first
                 else
                   Person.where({
                                  :dob => dob,
                                  :last_name => last_name_regex,
                                  :first_name => first_name_regex
                                }).last
                 end
        person.present? ? Success(person) : Failure('Failed to find primary person in xml')
      end

      def fetch_family(person)
        family = person.primary_family
        family ? Success(family) : Failure('Failed to find primary family for users person in xml')
      end

      def fetch_active_household(family)
        Success(family.active_household)
      end

      def fetch_household_from_parsed_object(parsed_object)
        Success(parsed_object.households.max_by(&:start_date))
      end

      def check_if_dependents_exist_in_ea(dependents)
        dependents.each do |verified_family_member|
          result = fetch_person(verified_family_member)
          return Failure('Failed to find dependent from xml') if result.failure?

          next
        end
        Success(true)
      end

      def set_integrated_case_id(family, parsed_object)
        family.e_case_id = parsed_object.integrated_case_id
        Success(family.save!)
      end

      def create_tax_households(active_household, parsed_object, primary_person, household_from_payload, application)
        result = active_household.create_tax_households_and_members(parsed_object, primary_person, household_from_payload,
                                                                                                               application)
        Success(result)
      rescue StandardError
        Failure('Failure to update tax household')
      end

    end
  end
end
