# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class CreateOrUpdate
      include Dry::Monads[:result, :do]

      PersonCandidate = Struct.new(:ssn, :dob, :first_name, :last_name)

      def call(params:)
        person_values = yield validate(params)
        person_entity = yield create_entity(person_values)
        person = yield match_or_create_person(person_entity.to_h)

        Success(person)
      end

      private

      def sanitize_params(params)
        params[:hbx_id] = params.delete :person_hbx_id
        params
      end

      def validate(params)
        result = Validators::PersonContract.new.call(sanitize_params(params))

        if result.success?
          Success(result)
        else
          Failure(result)
        end
      end

      def create_entity(values)
        result = Entities::Person.new(values.to_h)

        Success(result)
      end

      def match_or_create_person(person_entity)
        person = if person_entity[:no_ssn] == '1'
                   PersonCandidate.new(person_entity[:first_name], person_entity[:last_name], person_entity[:dob])
                   Person.where(first_name: /^#{person_entity[:first_name]}$/i, last_name: /^#{person_entity[:last_name]}$/i,
                                dob: person_entity[:dob]).first # TODO Need to
                 else
                   candidate = PersonCandidate.new(person_entity[:ssn], person_entity[:dob])
                   Person.match_existing_person(candidate)
                 end

        if person.blank?
          person = Person.new(person_entity.to_h) #if person_valid_params.success?
          person.save!
        else
          create_or_update_associations(person, person_entity.to_h, :addresses)
          create_or_update_associations(person, person_entity.to_h, :emails)
          create_or_update_associations(person, person_entity.to_h, :phones)
        end

        Success(person)
      rescue StandardError => e
        Failure(person.errors.messages)
      end

      def create_or_update_associations(person, applicant_params, assoc)
        records = applicant_params[assoc.to_sym]
        return if records.empty?

        records.each do |attrs|
          address_matched = person.send(assoc).detect {|adr| adr.kind == attrs[:kind]}
          if address_matched
            address_matched.update(attrs)
          else
            person.send(assoc).create(attrs)
          end
        end
      end
    end
  end
end

