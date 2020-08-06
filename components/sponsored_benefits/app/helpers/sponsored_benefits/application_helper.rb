# frozen_string_literal: true

module SponsoredBenefits
  module ApplicationHelper
    def generate_breadcrumb_links(proposal, organization)
      if proposal.persisted?
        links = [sponsored_benefits.edit_organizations_plan_design_organization_plan_design_proposal_path(organization.id, proposal.id)]
        links << sponsored_benefits.new_organizations_plan_design_proposal_plan_selection_path(proposal)
      else
        links = [sponsored_benefits.new_organizations_plan_design_organization_plan_design_proposal_path(organization.id)]
      end
      links << sponsored_benefits.new_organizations_plan_design_proposal_plan_review_path(proposal) unless proposal.active_benefit_group.nil?
      links
    end

    def eligibility_criteria(employer)
      # TODO: - See why do we have this dependency in DC.
    end
  end
end
