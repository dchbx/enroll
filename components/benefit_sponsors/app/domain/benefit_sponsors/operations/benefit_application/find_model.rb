# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitApplication
      # Finds benefit application with the given id
      class FindModel
        include Dry::Monads[:result, :do]

        # @param  [ String ] benefit_application_id Benefit Application ID as string
        # @return [ BenefitApplication ] BenefitApplication object

        def call(params)
          benefit_application = yield benefit_application(params[:benefit_application_id])

          Success(benefit_application)
        end

        private

        def benefit_application(benefit_application_id)
          benefit_application = BenefitSponsors::BenefitApplications::BenefitApplication.find(benefit_application_id)

          if benefit_application
            Success(benefit_application)
          else
            Failure('BenefitApplication not found')
          end
        end
      end
    end
  end
end