# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class CreateOrUpdate
      include Dry::Monads[:result, :do]

      def call(params:)
        person_values = yield validate(params)
        person_entity = yield create_entity(person_values)
        person = yield match_or_update_or_create_person(person_entity.to_h)

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

      def match_or_update_or_create_person(person_entity)
        person = Person.by_hbx_id(person_entity.to_h[:hbx_id]).first

        #create new person
        if person.blank?
          person = Person.new(person_entity.to_h) #if person_valid_params.success?
          person.save!
        else
          return Success(person) if no_infomation_changed?({params: {attributes_hash: person_entity, person: person}})

          person.assign_attributes(person_entity.except(:addresses, :phones, :emails))
          person.save!
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

      def no_infomation_changed?(params:)
        result = ::Operations::People::CompareForDataChange.new.call(params: params)
        result.failure?
      end
    end
  end
end
