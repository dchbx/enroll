module QleKinds
  class UpdateParamsValidator < ::BenefitSponsors::BaseParamValidator
    define do
      required(:id).filled(:str?)
      required(:title).filled(:str?)
      required(:pre_event_sep_in_days).filled
      required(:post_event_sep_in_days).filled
      required(:effective_on_kinds).value(:array?, min_size?: 1)
      required(:market_kind).value(:filled?, included_in?: QualifyingLifeEventKind::MARKET_KINDS)
      optional(:is_self_attested).filled(::Dry::Types["params.bool"])
      optional(:visible_to_customer).filled(::Dry::Types["params.bool"])
      optional(:custom_qle_questions).maybe(:array?)
      optional(:tool_tip).maybe(:str?)
      optional(:reason).maybe(:str?)
      optional(:start_on).maybe(:str?)  
      optional(:end_on).maybe(:str?)
    end
  end
end