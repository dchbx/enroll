# Takes the given contribution model and produces the needed objects for that
# model to place under the Sponsoring profile.
module BenefitMarkets
  class ContributionModels::ContributionModelBuilder
    def build_sponsor_contribution(contribution_model)
      contribution_model.sponsor_contribution_kind.constantize.new
    end

    # Produce the contribution levels specified by the given contribution model
    def build_contribution_levels(contribution_model, sponsor_contribution)
      contribution_model.contribution_units.map do |cu|
        cv = sponsor_contribution.contribution_levels.build
        cu.assign_contribution_value_defaults(cv)
        cv
      end
    end
  end
end
