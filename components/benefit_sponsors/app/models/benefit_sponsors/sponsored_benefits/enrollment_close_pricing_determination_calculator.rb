module BenefitSponsors
  module SponsoredBenefits
    class EnrollmentClosePricingDeterminationCalculator
      def self.call(benefit_application, calc_date)
        calculator = ::BenefitSponsors::SponsoredBenefits::HbxEnrollmentPricingDeterminationCalculator.new(benefit_application.benefit_sponsorship, benefit_application.open_enrollment_end_on)
        benefit_application.benefit_packages.each do |bp|
          bp.sponsored_benefits.each do |sb|
            enrollment_count, waiver_count = enrollment_and_waiver_count_for(sb, benefit_application.start_on)
            enrollment_id_list = enrollment_id_list_for(sb, benefit_application.start_on)
            updated_benefit = calculator.calculate(sb, enrollment_id_list, enrollment_count, waiver_count)
            sb.save!
          end
        end
      end

      def self.enrollment_and_waiver_count_for(sb, effective_date)
        query = ::Queries::NamedEnrollmentQueries.query_for_initial_sponsored_benefit(sb, effective_date)
        cancel_cutoff = ::Queries::NamedEnrollmentQueries.initial_sponsored_benefit_last_cancel_chance(sb)
        enrollment_counter = ::Queries::NamedEnrollmentQueries::EnrollmentCounter.new(cancel_cutoff,[query])
        enrollment_counter.calculate_totals
      end

      def self.enrollment_id_list_for(sb, effective_date)
        query = ::Queries::NamedEnrollmentQueries.query_for_initial_sponsored_benefit(sb, effective_date)
        cancel_cutoff = ::Queries::NamedEnrollmentQueries.initial_sponsored_benefit_last_cancel_chance(sb)
        ::Queries::NamedEnrollmentQueries::InitialEnrollmentFilter.new(cancel_cutoff, [query])
      end
    end
  end
end
