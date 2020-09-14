# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class Persist
      include Dry::Monads[:result, :do]

      def call(params:)
        person_params = yield validate(params)
        person_entity = yield initialize_entities(person_params)
        person = yield match_or_create_person(person_entity)
        # consumer_role = yield create_or_update_consumer_role(person)

        Success(person)
      end

      private

      def validate(params)
        result = Validators::PersonContract.new.call(params)

        if result.success?
          Success(result)
        else
          Failure(result)
        end
      end

      def initialize_entities(values)
        result = Entities::Person.new(values.to_h)

        Success(result)
      end

      def match_or_create_person(person_entity)
        person_hash = person_entity.to_h
        matched_people = Person.where(
          first_name: regex_for(person_hash[:first_name]),
          last_name: regex_for(person_hash[:last_name]),
          dob: person_hash[:dob],
          encrypted_ssn: Person.encrypt_ssn(person_hash[:ssn])
        )
        raise TooManyMatchingPeople if matched_people.count > 1

        person = if matched_people.count == 1
                   matched_people.first
                 else
                   Person.new(person_hash)
                 end

        person.save!

        Success(person)
      rescue StandardError => e
        error_on_save = person.errors.messages
        Failure([error_on_save])
      end

      def self.encrypt_ssn(val)
        if val.blank?
          return nil
        end
        ssn_val = val.to_s.gsub(/\D/, '')
        SymmetricEncryption.encrypt(ssn_val)
      end

      def dob=(val)
        @dob = begin
          Date.strptime(val, "%Y-%m-%d")
        rescue StandardError
          nil
        end
      end

      def regex_for(str)
        ::Regexp.compile(::Regexp.escape(str.to_s))
      end
    end
  end
end

