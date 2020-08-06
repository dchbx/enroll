# frozen_string_literal: true

module SponsoredBenefits
  module Services
    class PlanDesignProposalService

      attr_reader :proposal, :kind

      def initialize(attrs = {})
        @kind = attrs[:kind]
        @proposal = attrs[:proposal]
      end

      def ensure_benefits
        self.send("ensure_#{kind}_benefits")
      end

      def save_benefits(attrs = {})
        self.send("save_#{kind}_benefits", attrs)
      end

      def destroy_benefits
        # we can only destroy dental benefits
        reset_dental_benefits
        benefit_group.update_attributes(dental_reference_plan_id: nil)
      end

      def ensure_health_benefits
        benefit_group.build_relationship_benefits if benefit_group.relationship_benefits.empty?
        benefit_group.build_composite_tier_contributions if benefit_group.sole_source? && benefit_group.composite_tier_contributions.empty?
        benefit_group
      end

      def ensure_dental_benefits
        benefit_group.build_dental_relationship_benefits if benefit_group.dental_relationship_benefits.empty?
        benefit_group
      end

      def save_health_benefits(attrs = {})
        benefit_group = benefit_group(
          attrs.merge!(
            {
              title: "Benefit Group Created for: #{plan_design_organization.legal_name} by #{plan_design_organization.broker_agency_profile.legal_name}"
            }
          )
        )
        update_benefits(attrs) if benefit_group.persisted?
        benefit_group.elected_plans = benefit_group.elected_plans_by_option_kind

        benefit_group.build_composite_tier_contributions if benefit_group.sole_source? && benefit_group.composite_tier_contributions.empty?

        if benefit_group.sole_source?
          benefit_group.build_relationship_benefits
          benefit_group.estimate_composite_rates
        end

        benefit_group.set_bounding_cost_plans
      end

      def save_dental_benefits(attrs = {})
        update_benefits(attrs)
        benefit_group.elected_dental_plans = benefit_group.elected_dental_plans_by_option_kind
        benefit_group.set_bounding_cost_dental_plans
      end

      def update_benefits(attrs = {})
        self.send("reset_#{kind}_benefits")
        benefit_group.title = "Benefit Group Created for: #{plan_design_organization.legal_name} by #{plan_design_organization.broker_agency_profile.legal_name}"
        if is_dental_benefits?
          benefit_group.update_attributes({
                                            dental_plan_option_kind: attrs[:plan_option_kind],
                                            dental_reference_plan_id: attrs[:reference_plan_id],
                                            dental_relationship_benefits_attributes: attrs[:relationship_benefits_attributes].as_json
                                          })
        else
          benefit_group.update_attributes(attrs)
        end
      end

      def reset_health_benefits
        benefit_group.composite_tier_contributions.destroy_all if benefit_group.sole_source?
        benefit_group.relationship_benefits.destroy_all
      end

      def reset_dental_benefits
        benefit_group.dental_relationship_benefits.destroy_all
      end

      def plan_design_organization
        proposal.plan_design_organization
      end

      def benefit_group(attrs = {})
        return @benefit_group if defined? @benefit_group
        @benefit_group = application.benefit_groups.first || application.benefit_groups.build(attrs)
      end

      def application
        return @application if defined? @application
        sponsorship = proposal.profile.benefit_sponsorships.first
        @application = sponsorship.benefit_applications.first
      end

      def is_dental_benefits?
        kind == "dental"
      end

      def is_dental_plans_avialable?(form)
        ::Plan.where(
          coverage_kind: "dental",
          active_year: form.effective_date.year
        ).present?
      end
    end
  end
end
