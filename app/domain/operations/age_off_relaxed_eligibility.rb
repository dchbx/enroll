# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
module Operations
  #Operation checks for the age eligibility for dependents when plan shopping, relaxed eligibility operation allows the dependent to be able to shop for plans,
  # through out the defined eligibility period(annual/monthly) from yml based on the market settings.
  class AgeOffRelaxedEligibility
    include Config::SiteConcern
    include Dry::Monads[:result, :do]

    def call(effective_on:, family_member:, market_key:, relationship_kind:)
      _values        = yield validate(effective_on, family_member, market_key)
      age_off_period = yield fetch_age_off_period(market_key)
      cut_off_age    = yield fetch_cut_off_age(market_key)
      _relation      = yield validate_relationship(market_key, relationship_kind)
      result         = yield is_person_eligible_on_enrollment?(age_off_period, cut_off_age, effective_on, family_member, market_key)

      Success(result)
    end

    private

    def validate(effective_on, family_member, market_key)
      market_keys = [:aca_shop_dependent_age_off, :aca_fehb_dependent_age_off, :aca_individual_dependent_age_off]
      return Failure('Invalid effective_on') unless effective_on.is_a?(Date)
      return Failure('Invalid family_member') unless family_member.is_a?(FamilyMember)
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

    def is_person_eligible_on_enrollment?(age_off_period, cut_off_age, effective_on, family_member, market_key)
      person = family_member.person
      comparision_date = (age_off_period == :annual) ? effective_on.end_of_year : effective_on.end_of_month
      compare_26_old = (age_off_period == :annual) ? effective_on.beginning_of_year : effective_on.beginning_of_month
      age_on = person.age_on(comparision_date)
      if age_on > cut_off_age
        Failure('Not eligible')
      elsif age_on < cut_off_age
        Success('Eligible')
      elsif age_on == cut_off_age
        dob = person.dob
        if (dob + cut_off_age.years) < compare_26_old
          Failure('Not Eligible')
        else
          has_continuous_coverage?(family_member, market_key, effective_on, cut_off_age) ? Success('Eligible') : Failure('Not eligible')
        end
      end
    end

    # Checks to see if the family member has a continuous coverage until new effective_on
    def has_continuous_coverage?(family_member, market_key, effective_on, cut_off_age)
      return true if family_member.person.age_on(effective_on) < cut_off_age # checks for dependent who turns 26 in the same effective on month.
      kind = (market_key == :aca_individual_dependent_age_off) ? :individual_market : :shop_market
      enr = family_member.family.hbx_enrollments.enrolled_and_terminated.send(kind).where(:"hbx_enrollment_members.applicant_id" => family_member.id).effective_asc.last
      return false if enr.blank?
      enr.terminated_on.nil? || enr.terminated_on.next_day == effective_on
    end
  end
end