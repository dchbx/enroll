# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module Profiles
      class FindProfile
        include Dry::Monads[:result, :do]


        def call(params)
          benefit_sponsor_profile = yield benefit_sponsor_profile(params)

          Success(benefit_sponsor_profile)
        end

        private

        def benefit_sponsor_profile(params)
          sponsor_profile =
            if params[:profile_id]
              ::BenefitSponsors::Organizations::Profile.find(params[:profile_id])
            elsif params[:organization_id] && ['broker_agency', 'employer', 'general_agency'].include?(params[:profile_klass])
              organization = ::BenefitSponsors::Organizations::Organization.where(id: params[:organization_id]).first
              organization&.send("#{params[:profile_klass]}_profile".to_sym)
            end
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
