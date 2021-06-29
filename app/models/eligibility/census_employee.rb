# frozen_string_literal: true

module Eligibility
  module CensusEmployee
    def coverage_effective_on(package = nil, shop_under_current: false, shop_under_future: false)
      package = possible_benefit_package(shop_under_current: shop_under_current, shop_under_future: shop_under_future) if package.blank? || package.is_conversion? # cautious
      if package.present?
        effective_on_date = package.effective_on_for(hired_on)
        effective_on_date = [effective_on_date, newly_eligible_earlist_eligible_date].max if newly_designated?
        effective_on_date
      end
    end

    def new_hire_enrollment_period
      start_on = [hired_on, TimeKeeper.date_according_to_exchange_at(created_at)].max
      end_on = earliest_eligible_date.present? ? [start_on + 30.days, earliest_eligible_date].max : (start_on + 30.days)
      (start_on.beginning_of_day)..(end_on.end_of_day)
    end

    # TODO: eligibility rule different for active and renewal plan years
    def earliest_eligible_date
      possible_benefit_group_assignment&.benefit_package&.eligible_on(hired_on)
    end

    def newly_eligible_earlist_eligible_date
      possible_benefit_group_assignment&.benefit_package&.start_on
    end

    def earliest_effective_date
      possible_benefit_group_assignment&.benefit_package&.effective_on_for(hired_on)
    end

    def under_new_hire_enrollment_period?
      new_hire_enrollment_period.cover?(TimeKeeper.date_of_record)
    end

    def possible_benefit_group_assignment
      renewal_benefit_group_assignment || off_cycle_benefit_group_assignment || future_active_reinstated_benefit_group_assignment || active_benefit_group_assignment
    end
  end
end
