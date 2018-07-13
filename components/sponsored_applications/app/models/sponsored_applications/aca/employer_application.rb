module SponsoredApplications
  class Aca::EmployerApplication < SponsoredApplications::SponsoredApplication

    # Employer self-attested full-time employee count
    field :fte_count, type: Integer, default: 0

    # Employer self-attested part-time employess
    field :pte_count, type: Integer, default: 0

    # Employer self-attested Medicare Second Payers
    field :msp_count, type: Integer, default: 0


    def add_marketplace_kind=(marketplace_kind)
      raise "marketplace must be aca_shop" unless marketplace_kind == :aca_shop
    end


    def add_sponsored_application
      raise "" if effective_term.blank?
    end

  private

    # Extend base class validations to include ACA-specific requirements
    def date_range_integrity
      super

      # TODO: remove this after tie-in to Settings
      return

      open_enrollment_term_maximum = Settings.aca.shop_market.open_enrollment.maximum_length.months.months
      if open_enrollment_term.end > (open_enrollment_term.begin + open_enrollment_term_maximum)
        errors.add(:open_enrollment_term, "may not exceed #{open_enrollment_term_maximum} months")
      end

      open_enrollment_term_earliest_begin = effective_term.begin - open_enrollment_term_maximum
      if open_enrollment_term.begin < open_enrollment_term_earliest_begin
        errors.add(:open_enrollment_begin_on, "may not begin more than #{open_enrollment_term_maximum} months sooner than effective date") 
      end

      initial_application_earliest_start_date = effective_term.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months
      if initial_application_earliest_start_date > TimeKeeper.date_of_record
        errors.add(:effective_term, "may not start application before #{initial_application_earliest_start_date.to_date} with #{effective_term.begin} effective date")
      end

      if !['canceled', 'suspended', 'terminated','termination_pending'].include?(aasm_state)
        benefit_term_minimum = Settings.aca.shop_market.benefit_period.length_minimum.year.years
        if end_on != (effective_term.begin + benefit_term_minimum - 1.day)
          errors.add(:effective_term, "application term period should be #{duration_in_days(benefit_term_minimum)} days")
        end
      end
    end


  end
end
