module Enrollments
  module Replicator
    class Individual < Base

      def determine_replication_type
        benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
        base_coverage_period = benefit_sponsorship.benefit_coverage_periods.by_date(base_enrollment.effective_on).first
        renewal_coverage_period = benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.contains?(base_coverage_period.start_on + 1.year) }

        new_coverage_period = benefit_sponsorship.benefit_coverage_periods.by_date(new_effective_date).first

        if base_coverage_period == new_coverage_period
          :reinstatement
        elsif renewal_coverage_period == new_coverage_period  
          :renewal
        else
          :unknown
        end
      end
    end
  end
end