module BenefitSponsors
  module Forms
    class SponsorContributionForm
      
      include Virtus.model
      include ActiveModel::Model

      attribute :contribution_levels, Array[ContributionLevelForm]
      attr_accessor :contribution_levels

      validates_presence_of :contribution_levels

      def contribution_levels_attributes=(attributes)
        @contribution_levels ||= []
        attributes.each do |i, contribution_level_attributes|
          @contribution_levels.push(ContributionLevelForm.new(contribution_level_attributes))
        end
      end

      def self.for_new
        form = self.new
        form.contribution_levels = ContributionLevelForm.for_new
        form
      end
    end
  end
end