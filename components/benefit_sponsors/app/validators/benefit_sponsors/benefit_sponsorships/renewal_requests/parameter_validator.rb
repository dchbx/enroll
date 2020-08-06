# frozen_string_literal: true

module BenefitSponsors
  module BenefitSponsorships
    module RenewalRequests
      class ParameterValidator < ::BenefitSponsors::BaseParamValidator
        define do
          required(:benefit_sponsorship_id).filled(::BenefitSponsors::BsonObjectIdString)
          required(:new_date).filter(format?: /\d{4}-\d{2}-\d{2}/).value(:date)
        end
      end
    end
  end
end
