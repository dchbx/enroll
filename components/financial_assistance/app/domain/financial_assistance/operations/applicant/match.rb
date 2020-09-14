# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applicant
      class Match
        send(:include, Dry::Monads[:result, :do])

        # @param [ Hash ] params Applicant Attributes
        # @return [ FinancialAssistance::Applicant ] applicant Applicant
        def call(params:, application:)
          applicant_attributes   = yield fetch_params(params)
          applicant = yield match_applicant(applicant_attributes, application)

          Success(applicant)
        end

        private

        def fetch_params(params)
          result_hash = { first_name: params[:first_name], last_name: params[:last_name], ssn: params[:ssn], dob: params[:dob] }
          Success(result_hash)
        end

        def match_applicant(attributes, application)
          ssn = attributes[:ssn]
          ssn = '' if ssn == '999999999'
          dob = attributes[:dob]
          last_name_regex = /^#{attributes[:last_name]}$/i
          first_name_regex = /^#{attributes[:first_name]}$/i
          matching_criteria = if ssn.present?
                                {:encrypted_ssn => FinancialAssistance::Applicant.encrypt_ssn(ssn), :dob => dob}
                              else
                                {:dob => dob, :last_name => last_name_regex, :first_name => first_name_regex}
                              end

          applicant = application.applicants.where(matching_criteria).first
          applicant ? Success(applicant) : Failure(nil)
        end
      end
    end
  end
end
