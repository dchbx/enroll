module Factories
  class PlanYearFactory
    def self.default_dates_for_coverage_starting_on(coverage_start_date)
      plan_year_start_on = coverage_start_date
      plan_year_end_on = coverage_start_date + 1.year - 1.day
      open_enrollment_start_on = plan_year_start_on - 2.months
      end_of_open_enrollment_month_start = coverage_start_date - 1.month
      open_enrollment_end_on = Date.new(end_of_open_enrollment_month_start.year, end_of_open_enrollment_month_start.month, Settings.aca.shop_market.open_enrollment.monthly_end_on)
      {
        start_on: plan_year_start_on,
        end_on: plan_year_end_on,
        open_enrollment_start_on: open_enrollment_start_on,
        open_enrollment_end_on: open_enrollment_end_on
      }
    end
  end
end
