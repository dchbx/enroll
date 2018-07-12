class CompositeRatingBaseRatesCalculator
  attr_reader :benefit_group, :plan

  def initialize(bg, plan)
    @benefit_group = bg
    @plan = plan
  end

  def base_rate
    @denominator ||= create_denominator
    return 0 if create_denominator == 0
    @base_rate ||= (create_numerator/@denominator).round(2)
  end

  def tier_rates
    base_rate_value = base_rate
    tier_rate_values = {}
    CompositeRatingTier::NAMES.each do |crt|
      crt_rate = benefit_group.composite_rating_tier_factor_for(crt, plan) * base_rate_value
      tier_rate_values[crt] = crt_rate.round(2)
    end
    tier_rate_values
  end

  def build_estimated_premiums
    rate_lookup = tier_rates
    benefit_group.composite_tier_contributions.each do |ctc|
      ctc.estimated_tier_premium = rate_lookup[ctc.composite_rating_tier]
    end
  end

  def assign_estimated_premiums
    build_estimated_premiums
    benefit_group.save!
  end

  def assign_final_premiums
    rate_lookup = tier_rates
    benefit_group.composite_tier_contributions.each do |ctc|
      ctc.final_tier_premium = rate_lookup[ctc.composite_rating_tier]
    end
    benefit_group.save!
  end

  protected

  def create_denominator
    grouped_denominators = selected_enrollment_objects.group_by { |eno| eno.composite_rating_tier }.map { |k, v| [k, v.size] }
    grouped_denominators.inject(0.00) do |acc, pair|
      crt, en_count = pair
      addition_value = en_count * benefit_group.composite_rating_tier_factor_for(crt, plan)
      (addition_value.round(2) + acc).round(2)
    end
  end

  def create_numerator
    selected_enrollment_objects.inject(0.00) do |acc, enrollment_obj|
      pcd = CompositeRatingListBillPrecalculator.new(plan, enrollment_obj, benefit_group)
      cost_for_this_enrollment = pcd.total_premium
      (cost_for_this_enrollment.round(2) + acc).round(2)
    end
  end

  # Returns either the census employees or the enrollments from the benefit group
  def selected_enrollment_objects
    benefit_group.composite_rating_enrollment_objects
  end
end
