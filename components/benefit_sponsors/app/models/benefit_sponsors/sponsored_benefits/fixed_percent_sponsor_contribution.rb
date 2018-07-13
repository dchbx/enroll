module BenefitSponsors
  module SponsoredBenefits
    class FixedPercentSponsorContribution < SponsorContribution
      def validate_contribution_levels
        return true if contribution_levels.blank?
        cls_fail = false
        contribution_levels.each do |cl|
          if cl.contribution_factor.blank?
            cl.errors.add(:contribution_factor, "must be provided")
            unless cls_fail
              errors.add(:contribution_levels, "is invalid")
              cls_fail = true
            end
          else
            if cl.contribution_factor < cl.min_contribution_factor
              cl.errors.add(:contribution_factor, "must be at least #{(cl.min_contribution_factor * 100).round(0)}")
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
