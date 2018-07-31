module BenefitSponsors
  module Organizations
    class BenefitSponsorProfileService

      # Benefit sponsor terminate, coverage is intertupted, becomes eligible again
      # 1) Create a new BenefitSponsorship
      # 2) Build roster from old roster
      def restore_sponsorship
      end


      # 1) If early termination, change enrollment period end date
      # 2) If exists, cancel renewing period benefit application
      # 3) Set benefit application to voluntary_terminated pending state
      def terminate_voluntarily(termination_date)
      end


      # 1) Change enrollment period end date
      # 2) If exists, cancel renewing period benefit application
      # 3) Set benefit application to involuntary_terminated state
      def terminate_involuntarily(termination_date)
      end


      # 1) Set enrollments to coverage termination pending? -- Notifications, etc should 
      #    trigger from benefit sponsor state change
      def terminate(termination_date)
      end


      # Reverses a benefit sponsor's termination with no interuption of coverage
      def reinstate(benefit_application)
      end

    end
  end
end
