# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitSponsorship
      class FindModel
        include Dry::Monads[:result, :do]

        # @param  [ String ] benefit_sponsorship_id Benefit Sponsorship ID as string
        # @return [ BenefitSponsorship ] BenefitSponsorship object

        def call(params)
          benefit_sponsorship = yield benefit_sponsorship(params[:benefit_sponsorship_id])

          Success(benefit_sponsorship)
        end

        private

        def benefit_sponsorship(benefit_sponsorship_id)
          benefit_sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(id: benefit_sponsorship_id).first

          if benefit_sponsorship
            Success(benefit_sponsorship)
          else
            Failure('BenefitSponsorship not found')
          end
        end
      end
    end
  end
end