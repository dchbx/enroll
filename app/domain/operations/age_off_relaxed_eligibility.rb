# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
module Operations
  #Operation checks for the age eligibility for dependents when plan shopping, relaxed eligibility operation allows the dependent to be able to shop for plans,
  # through out the defined eligibility period(annual/monthly) from yml based on the market settings.
  class AgeOffRelaxedEligibility
    include Config::SiteConcern
    include Dry::Monads[:result, :do]

    def call(effective_on:, dob:, market_key:, relationship_kind:)
      _values        = yield validate(effective_on, dob, market_key)
      age_off_period = yield fetch_age_off_period(market_key)
      cut_off_age    = yield fetch_cut_off_age(market_key)
      _relation      = yield validate_relationship(market_key, relationship_kind)
      result         = yield is_person_eligible_on_enrollment?(age_off_period, cut_off_age, effective_on, dob)

      Success(result)
    end

    private

    def validate(effective_on, dob, market_key)
      market_keys = [:aca_shop_dependent_age_off, :aca_fehb_dependent_age_off, :aca_individual_dependent_age_off]
      return Failure('Invalid effective_on') unless effective_on.is_a?(Date)
      return Failure('Invalid dob') unless dob.is_a?(Date)
      return Failure('Invalid market_key') unless market_keys.include?(market_key)

      Success('Valid params')
    end

    def fetch_age_off_period(market_key)
      Success(EnrollRegistry[market_key].setting(:period).item)
    end

    def fetch_cut_off_age(market_key)
      Success(EnrollRegistry[market_key].setting(:cut_off_age).item)
    end

    def validate_relationship(market_key, relationship_kind)
      value = EnrollRegistry[market_key].setting(:relationship_kinds).item.include?(relationship_kind)
      value ? Success('Valid relationship kind') : Failure('Invalid relationship kind')
    end

    def is_person_eligible_on_enrollment?(age_off_period, cut_off_age, effective_on, dob)
      comparision_date = (age_off_period == :annual) ? effective_on.beginning_of_year : effective_on.beginning_of_month
      true_or_false = (dob + cut_off_age.years) >= comparision_date
      true_or_false ? Success('Eligible') : Failure('Not eligible')
    end
  end
end
