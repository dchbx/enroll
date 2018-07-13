module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationEnrollmentsMonthlyQuery

      attr_reader :benefit_application

      def initialize(benefit_application)
        @benefit_application = benefit_application
      end

      def call(date)
        families = Family.where({
          :"households.hbx_enrollments.benefit_group_id".in => benefit_package_ids,
          :"households.hbx_enrollments.aasm_state".in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
          }).limit(100)

        families.inject([]) do |enrollments, family|
          valid_enrollments = family.active_household.hbx_enrollments.where({
            :benefit_group_id.in => benefit_package_ids,
            :effective_on.lte => date.end_of_month,
            :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
            }).order_by(:'submitted_at'.desc)

          health_enrollments = valid_enrollments.where({:coverage_kind => 'health'})
          dental_enrollments = valid_enrollments.where({:coverage_kind => 'dental'})

          coverage_filter = lambda do |enrollments, date|
            enrollments = enrollments.select{|e| e.terminated_on.blank? || e.terminated_on >= date}

            if enrollments.size > 1
              enrollment = enrollments.detect{|e| (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES).include?(e.aasm_state.to_s)}
              enrollment || enrollments.detect{|e| HbxEnrollment::RENEWAL_STATUSES.include?(e.aasm_state.to_s)}
            else
              enrollments.first
            end
          end

          enrollments << coverage_filter.call(health_enrollments, date)
          enrollments << coverage_filter.call(dental_enrollments, date)
        end.compact
      end

      def benefit_package_ids
        benefit_application.benefit_packages.collect(&:_id)
      end
    end
  end
end