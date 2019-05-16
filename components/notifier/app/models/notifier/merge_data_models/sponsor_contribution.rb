 # frozen_string_literal: true

module Notifier
  module MergeDataModels
    class SponsorContribution
      include Virtus.model

      attribute :contribution_levels, Array[MergeDataModels::ContributionLevel]

      def self.stubbed_object
        sponsor_contribution = Notifier::MergeDataModels::SponsorContribution.new
        sponsor_contribution.contribution_levels = Notifier::MergeDataModels::ContributionLevel.stubbed_object
        sponsor_contribution
      end
    end
  end
end