# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module Profiles
      class FindProfile
        include Dry::Monads[:result, :do]


        def call(params)
          benefit_sponsor_profile = yield benefit_sponsor_profile(params[:profile_id])

          Success(benefit_sponsor_profile)
        end

        private

        def benefit_sponsor_profile(profile_id)
          sponsor_profile = ::BenefitSponsors::Organizations::Profile.find(profile_id)

          if sponsor_profile
            Success(sponsor_profile)
          else
            Failure({:message => ['Profile not found']})
          end
        end
      end
    end
  end
end
