# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Application
      class RelationshipHandler
        send(:include, Dry::Monads[:result, :do])

        # @param [ Hash ] params Applicant Attributes
        # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
        def call(params)
          _values = yield validate(params)
          _filter_result = yield filter(params)
          result = yield transmit_data

          Success(result)
        end

        private

        def validate(params)
          result = params[:relationship].is_a?(FinancialAssistance::Relationship)
          Success(result)
        end


        def filter(params)
          @application = params[:relationship].application
          applicant = params[:relationship].applicant
          @dependent = params[:relationship].relative
          if applicant.is_primary_applicant?
            Success('Notify enroll app')
          else
            Failure('Do not notify enroll app')
          end
        end

        def transmit_data
          begin
            Operations::Families::CreateOrUpdateMember.new.call(params: {applicant_params: @dependent.attributes_for_export, family_id: @application.family_id})
          rescue StandardError => e
            Rails.logger.error {"Unable to deliver due to #{e}"} unless Rails.env.test?
          end

          Success('Successfully notified enroll app')
        end
      end
    end
  end
end
