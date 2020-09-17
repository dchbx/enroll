# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applicant
      class CreateOrUpdate
        send(:include, Dry::Monads[:result, :do])

        #applicant attributes as type
        def call(params:, family_id:)
          values           = yield validate(params)
          @application     = yield find_draft_application(family_id)
          applicant_result = yield match_applicant(values, @application)
          _difference      = yield compare_values(values, applicant_result)
          result           = yield create_or_update(applicant_result, values)

          Success(result)
        end

        private

        def validate(params)
          ::FinancialAssistance::Validators::ApplicantContract.new.call(params)
        end

        def find_draft_application(family_id)
          application = ::FinancialAssistance::Application.where(family_id: family_id, aasm_state: 'draft').first
          if application
            Success(application)
          else
            Failure("Application Not Found")
          end
        end

        def match_applicant(values, application)
          result = ::FinancialAssistance::Operations::Applicant::Match.new.call(params: values.to_h, application: application)
          result.success? ? Success(result.success) : Success(nil)
        end

        def fetch_array_of_attrs_for_embeded_objects(data)
          new_arr = []
          data.each do |special_hash|
            new_arr << special_hash.except(:_id, :created_at, :updated_at, :tracking_version)
          end
          new_arr
        end

        def compare_values(values, applicant)
          return Success(nil) unless applicant.present?

          applicant_db_hash = applicant.serializable_hash.deep_symbolize_keys
          updated_applicant_hash = applicant_db_hash.inject({}) do |db_hash, element_hash|
                                       db_hash[element_hash[0]] = if [:addresses, :emails, :phones].include?(element_hash[0])
                                                                    fetch_array_of_attrs_for_embeded_objects(element_hash[1])
                                                                  else
                                                                    element_hash[1]
                                                                  end
                                       db_hash
                                     end
          updated_applicant_hash.merge!({relationship: applicant.relation_with_primary, ssn: applicant.ssn})
          incoming_values = values.to_h.deep_symbolize_keys
          merged_params = updated_applicant_hash.merge(incoming_values)

          if any_information_changed?(merged_params, updated_applicant_hash)
            Success('Information has changed')
          else
            Failure('No information is changed')
          end
        end

        def create_or_update(applicant_result, values)
          applicant = if applicant_result.present?
                        applicant_result
                      else
                        @application.applicants.build
                      end
          applicant.assign_attributes(values.to_h)

          if applicant.save
            Success(applicant)
          else
            Failure(applicant.errors)
          end
        end

        def any_information_changed?(merged_params, updated_applicant_hash)
          return true if merged_params.except(:addresses, :emails, :phones) != updated_applicant_hash.except(:addresses, :emails, :phones)
          return true if Set.new(merged_params[:addresses]) != Set.new(updated_applicant_hash[:addresses])
          return true if Set.new(merged_params[:emails]) != Set.new(updated_applicant_hash[:emails])
          return true if Set.new(merged_params[:phones]) != Set.new(updated_applicant_hash[:phones])
        end
      end
    end
  end
end
