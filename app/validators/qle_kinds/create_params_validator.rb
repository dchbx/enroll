module QleKinds
  class CreateParamsValidator < ::BenefitSponsors::BaseParamValidator
    define do
      required(:title).filled(:str?)
      required(:pre_event_sep_in_days).filled
      required(:post_event_sep_in_days).filled
      required(:effective_on_kinds).value(:array?, min_size?: 1)
      required(:market_kind).value(:filled?, included_in?: QualifyingLifeEventKind::MARKET_KINDS)
      required(:is_self_attested).filled(::Dry::Types["params.bool"])
      required(:visible_to_customer).filled(::Dry::Types["params.bool"])
      optional(:tool_tip).maybe(:str?)
      optional(:reason).maybe(:str?)
      optional(:start_on).maybe(:str?)
      optional(:end_on).maybe(:str?)
      # Not required
      optional(:custom_qle_questions).maybe(:array?)
    end
  end
end