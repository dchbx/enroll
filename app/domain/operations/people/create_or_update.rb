# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class CreateOrUpdate
      include Dry::Monads[:result, :do]

      PersonCandidate = Struct.new(:ssn, :dob)

      def call(params:)
        person_params = yield validate(params)
        person_entity = yield initialize_entities(person_params)
        person = yield match_or_create_person(person_entity)

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
        candidate = PersonCandidate.new(person_entity[:ssn], person_entity[:dob])
        person = Person.match_existing_person(candidate)

        if person.blank?
          person = Person.new(person_entity) #if person_valid_params.success?

          return false unless try_create_person(person)
        end

        Success(person)
      rescue StandardError => e
        error_on_save = person.errors.messages
        Failure([error_on_save])
      end

      def try_create_person(person)
        person.save.tap do
          bubble_person_errors(person)
        end
      end

      def bubble_person_errors(person)
        self.errors.add(:ssn, person.errors[:ssn]) if person.errors.key?(:ssn)
      end
      #
      # def self.encrypt_ssn(val)
      #   if val.blank?
      #     return nil
      #   end
      #   ssn_val = val.to_s.gsub(/\D/, '')
      #   SymmetricEncryption.encrypt(ssn_val)
      # end

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

