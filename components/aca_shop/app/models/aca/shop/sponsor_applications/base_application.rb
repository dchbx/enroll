module Aca
  module Shop
    module BenefitApplication
      module BaseApplication
        include SetCurrentUser
        include Mongoid::Document
        include Mongoid::Timestamps

        include AASM
        include Acapi::Notifiers

        # Effective date period
        field :effective_start_on, type: Date
        field :effective_end_on, type: Date

        field :open_enrollment_start_on, type: Date
        field :open_enrollment_end_on, type: Date

        field :terminated_on, type: Date

        # Number of full-time employees
        field :fte_count, type: Integer, default: 0

        # Number of part-time employess
        field :pte_count, type: Integer, default: 0

        # Number of Medicare Second Payers
        field :msp_count, type: Integer, default: 0

        # Workflow status
        field :aasm_state, type: String, default: :draft

        embeds_many :workflow_state_transitions, as: :transitional

        validates_presence_of :effective_start_on, :effective_end_on, 
                              :open_enrollment_start_on, :open_enrollment_end_on, :message => "is invalid"

        validate :application_date_checks

      private

        def application_date_checks
          return if canceled? || expired? || renewing_canceled?
          return if start_on.blank? || end_on.blank? || open_enrollment_start_on.blank? || open_enrollment_end_on.blank?
          return if imported_plan_year

          if start_on != start_on.beginning_of_month
            errors.add(:effective_start_on, "must be first day of the month")
          end

          if end_on != end_on.end_of_month
            errors.add(:effective_end_on, "must be last day of the month")
          end

          if end_on > start_on.years_since(Settings.aca.shop_market.benefit_period.length_maximum.year)
            errors.add(:effective_end_on, "benefit period may not exceed #{Settings.aca.shop_market.benefit_period.length_maximum.year} year")
          end

          if open_enrollment_end_on > start_on
            errors.add(:effective_start_on, "can't occur before open enrollment end date")
          end

          if open_enrollment_end_on < open_enrollment_start_on
            errors.add(:open_enrollment_end_on, "can't occur before open enrollment start date")
          end

          if open_enrollment_start_on < (start_on - Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
            errors.add(:open_enrollment_start_on, "can't occur more than #{Settings.aca.shop_market.open_enrollment.maximum_length.months.months} months before start date")
          end

          if open_enrollment_end_on > (open_enrollment_start_on + Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
            errors.add(:open_enrollment_end_on, "open enrollment period is greater than maximum: #{Settings.aca.shop_market.open_enrollment.maximum_length.months} months")
          end

          if (start_on + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months) > TimeKeeper.date_of_record
            errors.add(:effective_start_on, "may not start application before " \
              "#{(start_on + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months).to_date} with #{start_on} effective date")
          end

          if !['canceled', 'suspended', 'terminated'].include?(aasm_state)
            if end_on != (start_on + Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)
              errors.add(:effective_end_on, "plan year period should be: #{duration_in_days(Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)} days")
            end
          end
        end

      end
    end
  end
end