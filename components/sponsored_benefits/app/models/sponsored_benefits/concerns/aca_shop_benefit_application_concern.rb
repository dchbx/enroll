require 'active_support/concern'

module SponsoredBenefits
  module Concerns::AcaShopBenefitApplicationConcern
    extend ActiveSupport::Concern

    # Move ACA-specific PlanYear code here. e.g. Rating areas, Geographic Rating Areas, etc

    included do
      # Number of full-time employees
      field :fte_count, type: Integer, default: 0

      # Number of part-time employess
      field :pte_count, type: Integer, default: 0

      # Number of Medicare Second Payers
      field :msp_count, type: Integer, default: 0

      # Calculated Fields for DataTable
      field :enrolled_summary,  type: Integer, default: 0
      field :waived_summary,    type: Integer, default: 0
    end


    def validate_application_dates
      open_enrollment_period_maximum = Settings.aca.shop_market.open_enrollment.maximum_length.months.months
      if open_enrollment_period.end > (open_enrollment_period.begin + open_enrollment_period_maximum)
        errors.add(:open_enrollment_period, "may not exceed #{open_enrollment_period_maximum} months")
      end

      open_enrollment_period_earliest_begin = effective_period.begin - open_enrollment_period_maximum
      if open_enrollment_period.begin < open_enrollment_period_earliest_begin
        errors.add(:open_enrollment_period, "may not begin more than #{open_enrollment_period_maximum} months sooner than effective date")
      end

      initial_application_earliest_begin_date = effective_period.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months
      if initial_application_earliest_begin_date > ::TimeKeeper.date_of_record
        errors.add(:effective_period, "may not start application before #{initial_application_earliest_begin_date.to_date} with #{effective_period.begin} effective date")
      end

      # We do not have AASM state in this model at the moment
      #
      # if !['canceled', 'suspended', 'terminated','termination_pending'].include?(aasm_state)
      #   benefit_period_minimum = Settings.aca.shop_market.benefit_period.length_minimum.year.years
      #   if end_on != (effective_period.begin + benefit_period_minimum - 1.day)
      #     errors.add(:effective_period, "application term period should be #{duration_in_days(benefit_period_minimum)} days")
      #   end
      # end
    end


  end
end
