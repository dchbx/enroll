module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationToPlanYearConverter

      attr_reader :benefit_application
      
      def initialize(benefit_application)
        @benefit_application = benefit_application
      end

      def call
        if application_valid?
          # CCA-specific attributes (move to subclass)
          recorded_sic_code               = ""
          recorded_rating_area            = ""

          copied_benefit_groups = []
          benefit_application.benefit_packages.each do |benefit_package|
            benefit_package.attributes.delete("_type")
            copied_benefit_groups << ::BenefitGroup.new(benefit_package.attributes)
          end

          ::PlanYear.new(
            start_on: benefit_application.effective_period.begin,
            end_on: benefit_application.effective_period.end,
            open_enrollment_start_on: benefit_application.open_enrollment_period.begin,
            open_enrollment_end_on: benefit_application.open_enrollment_period.end,
            benefit_groups: copied_benefit_groups
            )
        end
      end

      def application_valid?
        raise "Invalid number of benefit_packages: #{benefit_application.benefit_packages.size}" if benefit_application.benefit_packages.size != 1
        benefit_application.benefit_sponsorship.present? && benefit_application.effective_period.present? && benefit_application.open_enrollment_period.present?
      end
    end
  end
end