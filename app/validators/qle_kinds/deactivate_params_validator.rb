module QleKinds
  class DeactivateParamsValidator < ::BenefitSponsors::BaseParamValidator
    define do
      required(:end_on).filled(:str?)
    end
  end
end