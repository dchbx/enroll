module BenefitSponsors
  module SponsoredBenefits
    class FixedPercentWithCapSponsorContribution < SponsorContribution
      def validate_contribution_levels
        super
        return true if contribution_levels.blank?
        cls_fail = false
        contribution_levels.each do |cl|
          if cl.contribution_cap.blank?
            cl.errors.add(:contribution_cap, "must be provided")
            unless cls_fail
              errors.add(:contribution_levels, "is invalid")
              cls_fail = true
            end
          else
            if cl.contribution_cap < 0.00
              cl.errors.add(:contribution_cap, "must be at least 0.00")
              unless cls_fail
                errors.add(:contribution_levels, "is invalid")
                cls_fail = true
              end
            end
          end
        end
        true
      end
    end
  end
end
