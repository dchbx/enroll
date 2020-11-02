# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class CompareForDataChange
      include Dry::Monads[:result, :do]

      def call(params:)
        values = yield validate(params)
        result = yield compare_values(values)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Missing keys') unless params.key?(:attributes_hash) || params.key?(:person)
        return Failure('Bad person object') unless params[:person].is_a?(::Person)

        Success(params)
      end

      def compare_values(values)
        incoming_values = values[:attributes_hash]
        person = values[:person]
        person_db_hash = person.serializable_hash.deep_symbolize_keys
        updated_person_hash = person_db_hash.inject({}) do |db_hash, element_hash|
                                db_hash[element_hash[0]] = if [:addresses, :emails, :phones].include?(element_hash[0])
                                                             fetch_array_of_attrs_for_embeded_objects(element_hash[1])
                                                           else
                                                             element_hash[1]
                                                           end
                                db_hash
                              end
        updated_person_hash.merge!({ssn: person.ssn})
        merged_params = updated_person_hash.merge(incoming_values.to_h.deep_symbolize_keys)
        if any_information_changed?(merged_params, updated_person_hash)
          Success('Information has changed')
        else
          Failure('No information is changed')
        end
      end

      def fetch_array_of_attrs_for_embeded_objects(data)
        new_arr = []
        data.each do |special_hash|
          new_arr << special_hash.symbolize_keys.except(:_id, :created_at, :updated_at, :tracking_version, :full_text, :location_state_code, :modifier_id, :primary)
        end
        new_arr
      end

      def any_information_changed?(merged_params, updated_person_hash)
        return true if merged_params.except(:addresses, :emails, :phones, :hbx_id) != updated_person_hash.except(:addresses, :emails, :phones, :hbx_id)
        return true if Set.new(merged_params[:addresses]) != Set.new(updated_person_hash[:addresses])
        return true if Set.new(merged_params[:emails]) != Set.new(updated_person_hash[:emails])
        return true if Set.new(merged_params[:phones]) != Set.new(updated_person_hash[:phones])
      end
    end
  end
end
